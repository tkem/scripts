#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Fcntl qw(:mode);
use File::stat;
use File::Spec;
use Getopt::Long;
use Pod::Usage;

my $mode = undef;
my $dirmode = undef;
my $umask = umask;

my $group = getgrgid $(;
my $owner = getpwuid $<;

sub mode {
    my $inode = shift;
    if (S_ISDIR($inode->mode)) {
        return $dirmode // $mode // $inode->mode & ~$umask;
    } else {
        return $mode // $inode->mode & ~$umask;
    }
}

sub fixperms {
    my ($file, $uid, $gid) = @_;
    my $inode = stat($file) or die "$0: cannot stat '$file': $!\n";

    if (S_ISDIR($inode->mode)) {
        opendir(my $fh, $file)
            or die "$0: cannot open directory '$file': $!\n";
        foreach (grep { !/^\.{1,2}$/ } readdir($fh)) {
            fixperms(File::Spec->catfile($file, $_), $uid, $gid);
        }
        closedir($fh);
    }

    chmod(mode($inode), $file)
        or die "$0: cannot change mode of '$file': $!\n";
    chown($uid, $gid, $file)
        or die "$0: cannot change ownership of '$file': $!\n";
}

GetOptions(
    'dirmode|d=o' => sub { $dirmode = oct($_[1]) },
    'group|g=s' => \$group,
    'mode|m=s' => sub { $mode = oct($_[1]) },
    'owner|o=s' => \$owner,
    'help|?' => sub { pod2usage(0) }
) or pod2usage(2);

my $uid = getpwnam($owner);
#$uid = int($owner) unless defined $uid or not defined getpwuid($owner);
die "$0: invalid user '$owner'\n" unless defined $uid;

my $gid = getgrnam($group);
#$gid = int($group) unless defined $gid or not defined getgrgid($group);
die "$0: invalid group: '$group'\n" unless defined $gid;

foreach my $file (@ARGV) {
    fixperms($file, $uid, $gid);
}

__END__

=head1 NAME

fixperms - fix permissions of files and directories

=head1 SYNOPSIS

B<fixperms> [I<OPTIONS> ...] I<FILE> ...

=head1 DESCRIPTION

B<fixperms> sets file and directory permissions.

=head1 OPTIONS

=over

=item B<-d>, B<--dirmode>=I<MODE>

set directory permission mode (octal)

=item B<-g>, B<--group>=I<GROUP>

set group ownership, instead of process' current group

=item B<-m>, B<--mode>=I<MODE>

set file permission mode (octal)

=item B<-o>, B<--owner>=I<OWNER>

set ownership (super-user only)

=item B<--help>

display this message and exit

=back

=head1 SEE ALSO

L<chmod(1)>, L<chown(1)>, L<dh_fixperms(1)>

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>

=cut
