# The jsonschema-benchmark entry point for JSON::Schema::Modern.
#
#   main.pl <schema.json> <instances.jsonl>
#
# Mirrors the other implementations: read the instance file, parse every instance (timed), add the schema (timed),
# validate every instance once cold, warm up, validate once more warm. Prints one line "cold,warm,compile,parse" in
# nanoseconds and exits non-zero if any instance is invalid.
use strict;
use warnings;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use Cpanel::JSON::XS ();
use JSON::Schema::Modern;

use constant WARMUP_ITERATIONS => 100;
use constant MAX_WARMUP_TIME => 10_000_000_000;    # 10 seconds
use constant SCHEMA_URI => 'https://jsonschema-benchmark.example/schema.json';

sub now { int(clock_gettime(CLOCK_MONOTONIC) * 1e9) }

sub read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "$path: $!\n";
    local $/;
    return scalar <$fh>;
}

sub validate_all {
    my ($js, $instances, $report) = @_;
    my $valid = 1;
    for my $i (0 .. $#$instances) {
        next if $js->evaluate($instances->[$i], SCHEMA_URI)->valid;
        print STDERR "Error validating instance $i\n" if $report;
        $valid = 0;
    }
    return $valid;
}

die "Usage: main.pl <schema> <instances>\n" unless @ARGV == 2;
my $json = Cpanel::JSON::XS->new->utf8->allow_nonref;
my $schema = $json->decode(read_file($ARGV[0]));
my @lines = grep { length } split /\n/, read_file($ARGV[1]);

my $parse_start = now();
my @instances = map { $json->decode($_) } @lines;
my $parse = now() - $parse_start;

# short_circuit stops at the first error: a yes-or-no answer, as the other implementations give. Formats are not
# asserted by default, and the benchmark's schema-noformat.json has none.
my $compile_start = now();
my $js = JSON::Schema::Modern->new(short_circuit => 1);
$js->add_schema(SCHEMA_URI, $schema);
my $compile = now() - $compile_start;

my $cold_start = now();
my $valid = validate_all($js, \@instances, 1);
my $cold = now() - $cold_start;

my $iterations = int((MAX_WARMUP_TIME + ($cold > 1 ? $cold : 1) - 1) / ($cold > 1 ? $cold : 1));
validate_all($js, \@instances, 0) for 1 .. ($iterations < WARMUP_ITERATIONS ? $iterations : WARMUP_ITERATIONS);

my $warm_start = now();
validate_all($js, \@instances, 0);
my $warm = now() - $warm_start;

print "$cold,$warm,$compile,$parse\n";
exit($valid ? 0 : 1);
