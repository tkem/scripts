#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;
use Pod::Usage;

my $umask = umask;
my $dirmode = 0;

my $mode = '644';
my $group = getgrgid $(;
my $owner = getpwuid $<;

sub fixperms {
    my ($file, $uid, $gid, $mode) = @_;
    print STDERR "fixperms: $file $uid - $gid - $mode\n";
    chown $uid, $gid, $file or die "$file: $!\n";
    chmod $mode, $file or die "$file: $!\n";
}

GetOptions(
    'dirmode|d=o' => \$dirmode,
    'group|g=s' => \$group,
    'mode|m=s' => \$mode,
    'owner|o=s' => \$owner,
    'help|?' => sub { pod2usage(1) }
) or pod2usage(2);

my $uid = getpwnam($owner);
#$uid = int($owner) unless defined $uid or not defined getpwuid($owner);
die "no such user: $owner\n" unless defined $uid;

my $gid = getgrnam($group);
#$gid = int($group) unless defined $gid or not defined getgrgid($group);
die "no such group: $group\n" unless defined $gid;

foreach my $file (@ARGV) {
    fixperms $file, $uid, $gid, oct($mode);
}

__END__

=head1 NAME

jsp2pm - Convert JSP to Perl modules

=head1 SYNOPSIS

jsp2pm [options] [file ...]

Options:
    -help           help message

