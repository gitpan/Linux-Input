package Linux::Input;

$VERSION = '1.00';

use base 'Class::Data::Inheritable';
use strict;
use warnings;

use Config;
use IO::File;
use IO::Select;

# class data
Linux::Input->mk_classdata('event_bytes');
Linux::Input->event_bytes(($Config{intsize} * 3) + ($Config{shortsize} * 2));
Linux::Input->mk_classdata('timeout');
Linux::Input->timeout(0.01);

# instaniate a new input device
sub new {
  my $class    = shift;
  my $filename = shift;
  my $self     = { };
  bless ($self => $class);

  $self->{fh} = IO::File->new("< $filename");
  die($!) unless ($self->{fh});

  return $self;
}

# get filehandle of device
sub fh {
  my $self = shift;
  return $self->{fh};
}

# $self's IO::Select object
sub selector {
  my $self = shift;
  unless ($self->{__io_select}) {
    $self->{__io_select} = IO::Select->new($self->fh());
  }
  return $self->{__io_select};
}

# poll for all pending events
sub poll {
  my $self     = shift;
  my $timeout  = shift || ref($self)->timeout();
  my $selector = $self->selector();
  my @ev;

  while (my ($fh) = $selector->can_read($timeout)) {
    my $buffer;
    my $len = sysread($fh, $buffer, Linux::Input->event_bytes);
    my ($sec, $usec, $type, $code, $value) =
      unpack('I!I!S!S!I!', $buffer);
    my $event = {
      tv_sec  => $sec,
      tv_usec => $usec,
      type    => $type,
      code    => $code,
      value   => $value,
    };
    push @ev, $event unless ($type == 0);
  }
  return @ev;
}

1;

__END__

=head1 NAME

Linux::Input - Linux input event interface

=head1 SYNOPSIS

Example: 1 Joystick using Event API

  my $js1 = Linux::Input->new('/dev/input/event3');
  while (1) {
    while (my @events = $js1->poll(0.01)) {
      foreach (@event) {
      }
    }
  }

Example: 2 Joysticks using Joystick API

  my $js1 = Linux::Input::Joystick->new('/dev/input/js0');
  my $js2 = Linux::Input::Joystick->new('/dev/input/js1');
  my $selector = IO::Select->new();
  $selector->add($js1->fh);
  $selector->add($js2->fh);

  while (my $fh = $selector->can_read) {
    my @event;
    if ($fh == $js1->fh) {
      @event = $js1->poll()
    } elsif ($fh == $js2->fh) {
      @event = $js2->poll()
    }
    foreach (@event) {
      # work
    }
  }

Example: monitor all input devices

  use File::Basename qw(basename);
  my @inputs = map { "/dev/input/" . basename($_) }
    </sys/class/input/event*>;

  my @dev;
  my $selector = IO::Select->new();
  foreach (@inputs) {
    my $device = Linux::Input->new($_);
    $selector->add($device->fh);
    push @dev, $device;
  }

  while (my $fh = $selector->can_read) {
    # work
  }

=head1 DESCRIPTION

L<Linux::Input> provides a pure-perl interface to the
Linux kernels input event interface.  It basically provides
a uniform API for getting data from all the different
input devices that Linux supports.

For more information, please read:
F</usr/src/linux/Documentation/input/input.txt>.

=head2 Class Methods

=head3 new

This method takes one filename as a parameter and returns
a L<Linux::Input> object.

B<Example>:

  my $js1 = Linux::Input->new('/dev/input/event3');

=head3 entity_bytes

This method returns the size of the event structure
on this system.

B<Example>:

  my $struct_size = Linux::Input->entity_bytes();

=head3 timeout

This method can be used to read or specify the default
timeout value for the select()'ing on filehandles that
happens within the module.  The default value is 0.01.

=head2 Object Methods

=head3 fh

This method returns the filehandle of a L<Linux::Input>
object.

B<Example>:

  my $filehandle = $js->fh();

=head3 selector

This method is used internally to return the
L<IO::Select> object that's been assigned to
the current L<Linux::Input> object.


=head3 poll

This method takes a C<$timeout> value as a parameter
and returns a list of C<@events> for the current
L<Linux::Input> object.

B<Example>:

  my @events = $js->poll(0.01);

=head1 AUTHOR

John Beppu (beppu@cpan.org)

=head1 SEE ALSO

L<Linux::Input::Joystick>,
L<Class::Data::Inheritable>,
L<IO::Select>,
L<IO::File>

=cut

# vim:sw=2 sts=2 expandtab
