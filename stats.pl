#!/usr/bin/perl
# stats -- print minimum, maximum, mean value and standard deviation

use strict;
use Getopt::Std;

my %opts = ( o => '%g' );
getopts("d:fo:qt", \%opts) or die << "EOT";
Usage: $0 [ -fqt ] [ -d DELIM ] [ -o FORMAT ] [ FILE... ]
EOT

local $| = 1 if $opts{f}; # autoflush on

my ($min, $max, $sum, $sum2, $n);

while (<>) {
    chomp;

    foreach ($opts{d} ? split /$opts{d}/ : ($_)) {
        my $val;

        if (/^-?\d*\.?\d+$/) {
            $val = $_;
        } elsif ($opts{t}) {
            if (/^(-?\d+):([0-5][0-9]\.?\d*)$/) {
                $val = $1 * 60 + $2;
            } elsif (/^(-?\d+):([0-5][0-9]):([0-5][0-9]\.?\d*)$/) {
                $val = $1 * 3600 + $2 * 60 + $3;
            } else {
                warn "$0: invalid argument: $_\n" unless $opts{q};
                next;
            }
        } else {
            warn "$0: invalid argument: $_\n" unless $opts{q};
            next;
        }

        $sum += $val;
        $sum2 += $val * $val;
        $min = $val if not defined $min or $val < $min;
        $max = $val if not defined $max or $val > $max;
        $n++;

        if ($opts{f}) {
            my $var = $n > 1 ? ($sum2 - $sum * $sum / $n) / ($n - 1) : 0;
            printf "$opts{o} $opts{o} $opts{o} $opts{o}\n", $min, $max, $sum / $n, sqrt($var);
        }
    }
}

if (!$opts{f} && $n) {
    my $var = $n > 1 ? ($sum2 - $sum * $sum / $n) / ($n - 1) : 0;
    printf "$opts{o} $opts{o} $opts{o} $opts{o} $opts{o}\n", $sum, $min, $max, $sum / $n, sqrt($var);
}
