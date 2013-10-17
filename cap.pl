#!/usr/bin/perl
# cap -- concatenate files and convert case

use strict;
use Getopt::Std;

my %opts = ();
getopts("lt", \%opts) or die << "EOT";
Usage: $0 [-lt] [file...]
EOT

$opts{u} = !($opts{l} || $opts{t});

while (<>) {
    $_ = uc if $opts{u};
    $_ = lc if $opts{l};
    s/(\pL[\pL']*)/\u$1/g if $opts{t};
    print;
}
