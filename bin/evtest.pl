#!/usr/bin/perl -w

use strict;
use Linux::Input::Joystick;
use Getopt::Long;

die ("Usage: $0 <device_file>...\n") if (!@ARGV);

my @dev = map { Linux::Input->new($_) } @ARGV;
my $selector = IO::Select->new( map { $_->fh } @dev );
my %dev_for_fh = map { $_->fh => $_ } @dev;

print "Press Ctrl-C to exit.\n";
my $i = 0;

while (1) {
  while (my @fh = $selector->can_read()) {
    foreach (@fh) {
      my $input_device = $dev_for_fh{$_};
      my @event = $input_device->poll(0.01);
      foreach my $ev (@event) {
	printf(
	  '%5d, %7d.%-7d, '.
	  'type => %4s, code => %4d, value => %d,'."\n",
	  $i++,
	  $ev->{tv_sec},
	  $ev->{tv_usec},
	  $ev->{type},
	  $ev->{code},
	  $ev->{value},
	);
      }
    }
  }
}

exit 0;

# vim:sw=2 sts=2
