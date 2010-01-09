package Plack::Session;
use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Util::Accessor qw( id is_new manager );

sub fetch_or_create {
    my($class, $request, $manager) = @_;

    my $id = $manager->state->extract($request);
    if ($id) {
        my $store = $manager->store->fetch($id);
        return $class->new( id => $id, _stash => $store, manager => $manager );
    } else {
        $id = $manager->state->generate($request);
        return $class->new( id => $id, _stash => {}, manager => $manager, is_new => 1 );
    }
}

sub new {
    my ($class, %params) = @_;
    bless { %params } => $class;
}

## Data Managment

sub dump {
    my $self = shift;
    $self->{_stash};
}

sub get {
    my ($self, $key) = @_;
    $self->{_stash}{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{_stash}{$key} = $value;
}

sub remove {
    my ($self, $key) = @_;
    delete $self->{_stash}{$key};
}

sub keys {
    my $self = shift;
    keys %{$self->{_stash}};
}

## Lifecycle Management

sub expire {
    my $self = shift;
    $self->{_stash} = {};
    $self->manager->store->cleanup( $self->id );
    $self->manager->state->expire_session_id( $self->id );
}

sub finalize {
    my ($self, $response) = @_;
    $self->manager->store->store( $self->id, $self );
    $self->manager->state->finalize( $self->id, $response );
}

1;

__END__

=pod

=head1 NAME

Plack::Session - Middleware for session management

=head1 SYNOPSIS

  use Plack::Session;

  my $store = Plack::Session::Store->new;
  my $state = Plack::Session::State->new;

  my $s = Plack::Session->new(
      store   => $store,
      state   => $state,
      request => Plack::Request->new( $env )
  );

  # ...

=head1 DESCRIPTION

This is the core session object, you probably want to look
at L<Plack::Middleware::Session>, unless you are writing your
own session middleware component.

=head1 METHODS

=over 4

=item B<new ( %params )>

The constructor expects keys in C<%params> for I<state>,
I<store> and I<request>. The I<request> param is expected to be
a L<Plack::Request> instance or an object with an equivalent
interface.

=item B<id>

This is the accessor for the session id.

=item B<state>

This is expected to be a L<Plack::Session::State> instance or
an object with an equivalent interface.

=item B<store>

This is expected to be a L<Plack::Session::Store> instance or
an object with an equivalent interface.

=back

=head2 Session Data Management

These methods allows you to read and write the session data like
Perl's normal hash. The operation is not synced to the storage until
you call C<finalize> on it.

=over 4

=item B<get ( $key )>

=item B<set ( $key, $value )>

=item B<remove ( $key )>

=item B<keys>

=back

=head2 Session Lifecycle Management

=over 4

=item B<expire>

This method can be called to expire the current session id. It
will call the C<cleanup> method on the C<store> and the C<finalize>
method on the C<state>, passing both of them the session id and
the C<$response>.

=item B<finalize ( $response )>

This method should be called at the end of the response cycle. It
will call the C<store> method on the C<store> and the
C<expire_session_id> method on the C<state>, passing both of them
the session id. The C<$response> is expected to be a L<Plack::Response>
instance or an object with an equivalent interface.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

