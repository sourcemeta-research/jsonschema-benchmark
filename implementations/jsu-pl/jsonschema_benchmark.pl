use 5.006;
use strict;
use warnings;

eval "use re::engine::RE2";   # try to replace regex engine
use List::Util qw( min );
use JSON::MaybeXS qw( decode_json );
use Getopt::Long qw(:config no_ignore_case);
use Time::HiRes 'time';

use schema qw( check_model_init check_model_mapper check_model_free );

sub decode_json_nonref($)
{
    my ($j) = @_;
    return decode_json($j, 1);
}

# options
my $debug = 0;

GetOptions("debug|D" => \$debug);

my $errors = 0;

check_model_init();
my $checker = check_model_mapper("");

my $values = [];

for my $file (@ARGV)
{
    my $contents;

    # read raw file contents
    if ($file ne "-") {
        open my $fh, "<", $file or die "cannot open file $file: $!";
        $contents = do { local $/ = undef; <$fh> };
        close $fh;
    }
    else {
        $contents = do { local $/ = undef; <STDIN> };
    }

    push @$values, (map { decode_json_nonref $_ } split /\n/, $contents);
}

# cold run, once, check results
warn("cold run\n") if $debug;
my $cold_start = time;
for my $j (@$values) {
    $errors++ unless &$checker($j, '', undef);
}
my $cold_stop = time;
my $cold_delay = 1_000_000 * ($cold_stop - $cold_start);  # µs

# warmup, at most 10 seconds
my $max = 1 + int(10_000_000.0 / $cold_delay);
my $n = min(1000, $max);
warn("warmup loop: $n\n") if $debug;
while ($n--)
{
    for my $j (@$values) {
        &$checker($j, '', undef);
    }
}

# hot run
warn("hot run\n") if $debug;
my $start = time;
for my $j (@$values) {
    &$checker($j, '', undef);
}
my $stop = time;
my $hot_delay = 1_000_000 * ($stop - $start);  # µs

# show rounded results
my $pass = @$values - $errors;
printf STDERR "pl validation: pass=$pass fail=$errors %.03f µs\n", $hot_delay;

my ($ns_cold, $ns_warm) = (int($cold_delay * 1E3 + 0.5), int($hot_delay * 1E3 + 0.5));
print "$ns_cold,$ns_warm\n";

check_model_free();

exit $errors ? 1 : 0;
