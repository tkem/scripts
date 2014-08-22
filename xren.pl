#!/usr/bin/perl
# xren - rename files using Perl expressions

use strict;
use Getopt::Std;

sub prompt {
    print "$0: @_? " if -t STDIN and -t STDOUT;
    return <STDIN> =~ /^\s*[Yy]/;
}

my %opts = ();
getopts("inuv", \%opts) and @ARGV >= 2 or die << "EOT";
Usage: $0 [-iuv] expr file...
EOT

my $expr = shift;

foreach (@ARGV) {
    warn "$0: $_: $!\n" and next unless -e;

    my $orig = $_;
    my $result = eval $expr;
    die "$0: $@\n" if $@;

    next unless $result;
    next if $opts{u} and -e $_ and -M $orig >= -M $_;
    next if $opts{i} and not prompt("$orig -> $_");

    print "$orig -> $_\n" if $opts{v};

    unless ($opts{n}) {
        rename $orig => $_ or warn "$0: $orig -> $_: $!\n";
    }
}

__END__

=head1 NAME

xren - rename files using Perl expressions

=head1 SYNOPSIS

B<xren> [B<-iuv>] I<expr> I<file>...

=head1 DESCRIPTION

B<xren> renames files and directories based on rules expressed as Perl
code.  The Perl expression I<expr> is evaluated for each I<file>, and
may alter the filename stored in C<$_>.  If I<expr> evaluates to
C<true>, the filename is changed to the new name in C<$_>.  This makes
B<xren> especially suited for use with Perl's
C<s/PATTERN/REPLACEMENT/> and C<tr/SEARCHLIST/REPLACEMENTLIST/>
operators.

=head1 OPTIONS

=over

=item B<-i>

Prompt before every rename.

=item B<-u>

Overwrite files only when the source file is newer than the
destination file.

=item B<-v>

Be verbose about what is being done.

=back

=head1 EXAMPLES

=over

=item Rename all C<.doc> files to C<.txt>:

B<xren 's/\.doc$/.txt/' *.doc>

=item Convert all uppercase letters to lowercase, prompting before
each rename:

B<xren -i 'tr/[A-Z]/[a-z]/' *.txt>

=item Same as above, but using Perl's C<lc> function:

B<xren -i '$_ = lc' *.txt>

=back

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>, based on code by Larry Wall.

=cut
