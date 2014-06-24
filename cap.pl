#!/usr/bin/perl
# cap -- concatenate files and convert case

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

# The U.S. Government Printing Office Style Manual
# <http://www.gpoaccess.gov/stylemanual/browse.html>
#
# [3.49] In matter set in caps and small caps or caps and lowercase,
# capitalize all principal words, including parts of compounds which
# would be capitalized standing alone. The articles a, an, and the;
# the prepositions at, by, for, in, of, on, to, and up; the
# conjunctions and, as, but, if, or, and nor; and the second element
# of a compound numeral are not capitalized.

my @gpo_lc = qw(a an the at by for in of on to up and as but if or nor);
my %gpo_lc = map { ($_, 1) } @gpo_lc;

my %opts = ();
getopts(":glt", \%opts) or die << "EOT";
Usage: $0 [-glt] [file...]
EOT

$opts{u} = not scalar keys %opts;

while (<>) {
    $_ = uc if $opts{u};
    $_ = lc if $opts{l};
    s/(\pL[\pL']*)/\u$1/g if $opts{t};
    s/(\pL[\pL']*)/$gpo_lc{$1} ? "$1" : "\u$1"/eg if $opts{g};
    print;
}
