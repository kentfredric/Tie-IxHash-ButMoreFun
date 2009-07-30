package Tie::IxHash::ButMoreFun;
our $VERSION = '1.0921113';


# ABSTRACT: A user-friendly wrapper to a Tie::IxHash object to fill some use case holes.



# $Id:$
use strict;
use warnings;

use Moose;
use MooseX::Types::Moose qw( :all );
use Tie::IxHash;
use Carp;
use namespace::autoclean;

has _hash => (
  is       => 'rw',
  isa      => 'Tie::IxHash',
  required => 1,
  default  => sub {
    return 'Tie::IxHash'->new();
  },
  handles => {
    _fetch   => 'FETCH',
    _exists  => 'EXISTS',
    _indices => 'Indices',
    _keys    => 'Keys',
    _values  => 'Values',
    _length  => 'Length',
    _push    => 'Push',
    _replace => 'Replace',
    _delete  => 'Delete',
  },
);


sub BUILDARGS {
  my $class  = shift;
  my (@inp)  = @_;
  my $object = Tie::IxHash->new();
  while (@inp) {
    my ( $key, $value ) = splice( @inp, 0, 2 );
    $object->Push( $key, $value );
  }
  return { _hash => $object };
}


sub has_key {
  my ( $self, $key ) = @_;
  return $self->_exists($key);
}


sub need_keys {
  my $self = shift;
  for ( 0 .. $#_ ) {
    my $key = $_[$_];
    unless ( $self->has_key($key) ) {
      Carp::cluck("Key $_ ( $key ) does not exist");
      return undef;
    }
  }
  return 1;
}


sub all_keys {
  my ($self) = @_;
  my @result = $self->_keys();
  return @result;
}


sub get_key_value {
  my ( $self, $key ) = @_;
  unless ( $self->need_keys($key) ) {
    Carp::cluck("Fetched key does not exist, cannot get");
    return undef;
  }

  my $i = $self->_indices($key);
  my $v = $self->_values($i);
  return $v;
}


sub set_key_value {
  my ( $self, $key, $value ) = @_;
  $self->_push( $key, $value );
  return $self;
}


sub length {
  my ($self) = @_;
  return $self->_length;
}


sub last {
  my ($self) = @_;
  return $self->_length - 1;
}


sub add_key {
  my $self    = shift;
  my $key     = shift;
  my $default = shift || undef;
  return $self if $self->has_key($key);
  $self->set_key_value( $key, $default );
}


sub copy_value {
  my ( $self, $from, $to ) = @_;
  unless ( $self->need_keys($from) ) {
    Carp::cluck("Source key does not exist, cannot copy");
    return undef;
  }

  my $value = $self->get_key_value($from);
  $self->set_key_value( $to, $value );
}


sub swap_values {
  my ( $self, $alpha, $beta ) = @_;
  unless ( $self->need_keys( $alpha, $beta ) ) {
    Carp::cluck("Both keys do not exist, cannot swap");
    return undef;
  }

  my $avalue = $self->get_key_value($alpha);
  my $bvalue = $self->get_key_value($beta);
  $self->set_key_value( $alpha, $bvalue );
  $self->set_key_value( $beta,  $avalue );
}


sub swap_keys {
  my ( $self, $alpha, $beta ) = @_;
  unless ( $self->need_keys( $alpha, $beta ) ) {
    Carp::cluck("Both keys do not exist, cannot swap");
    return undef;
  }
  my ($a_index) = $self->_indices($alpha);
  my ($a_value) = $self->_values($a_index);
  my ($b_index) = $self->_indices($beta);
  my ($b_value) = $self->_values($b_index);

  # You have to put temps in as placeholders
  # Or they'll change order
  # and you cant rename an index while its a duplicate

  # This incantation is hopefully good enough to make it unique.

  $self->_replace( $b_index, \0, "SWAP_KEYS_TEMP_$b_index" . [] );
  $self->_replace( $a_index, \0, "SWAP_KEYS_TEMP_$a_index" . [] );

  $self->_replace( $a_index, $b_value, $beta );
  $self->_replace( $b_index, $a_value, $alpha );
  return $self;
}


sub move_up {
  my ( $self, $key, $move ) = @_;
  $move ||= 1;
  unless ( $self->need_keys($key) ) {
    Carp::cluck("Key cant be moved up, it doesn't exist");
    return undef;
  }

  my $move_from = $self->_indices($key);
  my $move_to   = $move_from - $move;
  $move_to = 0 if $move_to < 0;

  # Copy Out the moving item.
  my ( $tk, $tv ) = ( $self->_keys($move_from), $self->_values($move_from) );

  # print "Get $move_from\n";

  # Move up everything inbetween, starting at
  # the lowest ( closet to 999 ) item

  my $i = $move_from - 1;
  while ( $i >= $move_to ) {
    $self->_move_down_one($i);
    $i--;
  }

  #print "Put $move_to\n";
  $self->_replace( $move_to, $tv, $tk );
  return $self;

}


sub move_down {

  my ( $self, $key, $move ) = @_;
  $move ||= 1;
  unless ( $self->need_keys($key) ) {
    Carp::cluck("Key cant be moved down, it doesn't exist");
    return undef;
  }

  my $move_from = $self->_indices($key);
  my $move_to   = $move_from + $move;
  $move_to = $self->last if $move_to > $self->last;

  # Copy Out the moving item.
  my ( $tk, $tv ) = ( $self->_keys($move_from), $self->_values($move_from) );

  #print "Get $move_from\n";

  # Move up everything inbetween, starting at
  # the highet ( closet to 0 ) item

  my $i = $move_from + 1;
  while ( $i <= $move_to ) {
    $self->_move_up_one($i);
    $i++;
  }

  #  print "Put $move_to\n";
  $self->_replace( $move_to, $tv, $tk );
  return $self;
}



sub _move_down_one {

  #
  #  6 => foo => valfoo
  #  7 => bar => valbar
  #
  #   x[] = foo, valfoo
  #   6 = ( HOLE , HOLE );
  #   7 = ( foo , valfoo );
  #
  my ( $self, $i ) = @_;
  my $k = $self->_keys($i);
  my $v = $self->_values($i);

  return $self if $i == $self->last;

  #print "cp $i -> " . ( $i + 1 ) . " , $i = HOLE \n";
  $self->_replace( $i, 'HOLE' . [], 'HOLE' . [] );
  $self->_replace( $i + 1, $v, $k );
  return $self;

}

sub _move_up_one {

  #
  #  6 => foo => valfoo
  #  7 => bar => valbar
  #
  #   x[] = bar, valbar
  #   7 = ( HOLE, HOLE );
  #   6 = ( bar , valbar );
  #
  my ( $self, $i ) = @_;
  my $k = $self->_keys($i);
  my $v = $self->_values($i);

  return $self if $i == 0;

  #print "cp $i -> " . ( $i - 1 ) . " , $i = HOLE \n";
  $self->_replace( $i, 'HOLE' . [], 'HOLE' . [] );
  $self->_replace( $i - 1, $v, $k );
  return $self;

}


sub IxHash {
  my $self = shift;
  my %hash;
  tie %hash, 'Tie::IxHash';
  for ( $self->all_keys ) {
    $hash{$_} = $self->get_key_value($_);
  }
  return \%hash;
}

1;


__END__

=pod

=head1 NAME

Tie::IxHash::ButMoreFun - A user-friendly wrapper to a Tie::IxHash object to fill some use case holes.

=head1 VERSION

version 1.0921113

=head1 SYNOPSIS

Tie::IxHash is a generally ok container, but I found the methods it provided lacking.

I didn't want to use native Hash interface anyway, just wanted a good datastorage for key-value pairs that permitted arbitrary order and order preservation.

    use aliased 'Tie::IxHash::ButMoreFun' => 'TIxBMF';

    my $i = TIxBMF->new();
    # {}
    $i->set_key_value( 'key' , 'value' );
    # { key => 'value' }
    $i->set_key_value( 'key2' , 'value' );
    # { key => 'value', key2 => 'value' );
    $i->swap_keys( 'key', 'key2' );
    # { key2 => 'value', key => 'value' }
    for( $i->all_keys ){
        my $v = $i->get_key_value( $_ );
        print "$_ => $v ";
    }

=head1 BETA

Code is still beta, interface is not yet deemed "stable", method names could change depending on things at this point.

This release is primarily a RFC. If somebody finds me something nicer, which does what I want without having to insert the hoop jumps I have here everywhere, then this might vanish altogther.

=head1 METHODS

=head2 has_key( $key )

returns true if the datastructure currently has $key set.

Semantically equivalent to:

    exists $hash{ $key }

=head2 need_keys ( $key, ... , $key )

Clucks + undef if all keys are not available
1 if otherwise.

=head2 all_keys()

returns a list of all keys in the datastructure

Semantically equivalent to:

    keys %hash;

except of course, keys are in a controlled order.

=head2 get_key_value( $key )

return the value of the key named $key

Semanticaly equivalent to:

    my $value = $hash{ $key };

=head2 set_key_value( $key , $value )

set the value of the key $key in the structure.

Equivalent to:

    $hash{ $key } = $value

Except of course, insertion order is retained.

=head2 length()

return how many keys there are

=head2 last()

return the number of the last key.

=head2 add_key( $key , $default = undef )

ensure that $key is in the datastructure.
if it is not there,  it is set to undef,

Semantically identical to:

    $hash{ $key } //=  ( $default // undef )

=head2 copy_value( $key1, $key2 )

copy the value of key1 to under the value of key2

Semantically identical to

    $hash{ $key2 } = $hash{ $key1 }

Order of keys is retained.

=head2 swap_values( $key1 , $key2  )

Swaps the values behind the named keys.

Akin to:

    my $v = $hash{ $key1 };
    $hash{ $key1 } = $hash{ $key2 };
    $hash{ $key2 } = $v;

=head2 swap_keys( $key1 , $key2 )

This works on the *order* of the keys, not the values,
Key<->value pairs should retain bonding, just the internal order will be
changed.

=head2 move_up( $key , $maxmove = 1 )

attempt to shift $key one position up ( closer to 0 )

=head2 move_down( $key , $maxmove  = 1)

attempt to shift the $key one position down ( closer to 999... )

=head2 _move_down_one( $index )

PRIVATE: INTERNAL USE ONLY.

Internal method called for shifting an entry down one place in the array.
If used wrongly will leave 'HOLEARRAY(0XF00AD)' style droppings in your data.

=head2 _move_up_one( $index )

PRIVATE: INTERNAL USE ONLY.

Internal method called for shifting an entry up one place in the array.
If used wrongly will leave 'HOLEARRAY(0XF00AD)' style droppings in your data.

=head2 IxHash()

Returns a hashref to an Actually Tied hash.
Note this is independant of our datastructure, as we don't use a tied hash internally,
only the IxHash container.

=head1 AUTHOR

  Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


