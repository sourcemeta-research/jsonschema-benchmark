# The jsonschema-benchmark entry point for Corvus.JsonSchema's native-backed Perl evaluator (JSON::Schema::Corvus::XS),
# which binds the corvus-json-schema C library.
#
#   main.pl <schema.json> <instances.jsonl>
#
# Mirrors the other implementations: read the instance file, parse every instance (timed), compile the schema (timed),
# validate every instance once cold, warm up, validate once more warm. Prints one line "cold,warm,compile,parse" in
# nanoseconds and exits non-zero if any instance is invalid.
use strict;
use warnings;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use JSON::Schema::Corvus::XS;

use constant WARMUP_ITERATIONS => 100;
use constant MAX_WARMUP_TIME => 10_000_000_000;    # 10 seconds

# The package's own parse: a document is JSON parsed once, for an instance validated more than once.
use constant PACKAGE => 'JSON::Schema::Corvus::XS';
use constant DOCUMENT => PACKAGE . '::Document';

sub now { int(clock_gettime(CLOCK_MONOTONIC) * 1e9) }

sub read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "$path: $!\n";
    local $/;
    return scalar <$fh>;
}

sub validate_all {
    my ($validator, $instances) = @_;
    my $valid = 1;
    for my $instance (@$instances) {
        $valid = 0 unless $validator->is_valid_document($instance);
    }
    return $valid;
}

die "Usage: main.pl <schema> <instances>\n" unless @ARGV == 2;
my $schema = read_file($ARGV[0]);
my @lines = grep { length } split /\n/, read_file($ARGV[1]);

my $parse_start = now();
my @instances = map { DOCUMENT->parse($_) } @lines;
my $parse = now() - $parse_start;

# The benchmark's schema-noformat.json has no `format` keywords; the defaults leave `format` as an annotation.
my $compile_start = now();
my $validator = PACKAGE->compile($schema);
my $compile = now() - $compile_start;

my $cold_start = now();
my $valid = validate_all($validator, \@instances);
my $cold = now() - $cold_start;

my $iterations = int((MAX_WARMUP_TIME + ($cold > 1 ? $cold : 1) - 1) / ($cold > 1 ? $cold : 1));
validate_all($validator, \@instances) for 1 .. ($iterations < WARMUP_ITERATIONS ? $iterations : WARMUP_ITERATIONS);

my $warm_start = now();
validate_all($validator, \@instances);
my $warm = now() - $warm_start;

print "$cold,$warm,$compile,$parse\n";
exit($valid ? 0 : 1);
