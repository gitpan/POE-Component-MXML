package POE::Component::MXML;

use strict;
use vars qw($VERSION);

$VERSION = '0.02';

use Carp qw(croak);

use POE::Session;

sub DEBUG () { 0 }

sub spawn {
  my ($type) = shift;

  croak qq($type requires an even number of parameters.)
    if @_ % 2;

  my %params = @_;
  #
  # Validate passed-in parameters
  #
  exists $params{Alias} or
    croak qq($type requires an Alias parameter.);
  exists $params{InputHandle} or
    croak qq($type requires an Input handle.);
  exists $params{Tag} or
    croak qq($type requires a Tag event to trigger.);
  #
  # Default parameter values
  #

  my $states = { _start  => \&poco_mxml_start,
                 get_tag => \&poco_mxml_get_tag,
               };
  if(ref(\$params{InputHandle}) eq 'SCALAR') { # Assume it's a file or text.
    if(-e $params{InputHandle}) {
      open FILE,"<$params{InputHandle}" or
        croak qq($type could not open $params{InputHandle}.);
      $params{Data} = join '',<FILE>;
      close FILE;
    } else {
      $params{Data} = $params{InputHandle};
    }
  } elsif(ref(\$params{InputHandle}) eq 'ARRAY') {
  } elsif(ref(\$params{InputHandle}) eq 'HASH') {
  } else {
  }

  DEBUG and do {
    warn <<_EOF_;

/--- spawning $type component --
| Alias       : $params{Alias}
| Tag         : $params{Tag}
| InputHandle : $params{InputHandle}
| Data        : $params{Data}
\\---
_EOF_
  };

  POE::Session->create
    ( inline_states => $states,
      args          => [%params],
    );
  undef;
}

#------------------------------------------------------------------------------

sub poco_mxml_start {
  my ($kernel,$heap) =
    @_[KERNEL,HEAP];
  for(my $i=ARG0; $i<@_; $i+=2)
    { $heap->{$_[$i]}=$_[$i+1] }
  $kernel->alias_set($heap->{Alias});
}

sub poco_mxml_get_tag {
  my ($heap,$sender) =
    @_[HEAP,SENDER];

  if($heap->{Data} =~ s,^<([^>]+)>([^<]*)</\1>,,s) { # Complete
    warn "Complete Tag : <$1>$2</$1>" if DEBUG;
    $sender->postback($heap->{Tag})->('Tag',$1,$2);
  } elsif($heap->{Data} =~ s,^<([^>]+)>([^<]+),,s) { # Open Tag
    warn "Opening Tag : <$1>$2" if DEBUG;
    push @{$heap->{tagstack}},$1;
    $sender->postback($heap->{Tag})->('Open_Tag',$1,$2);
  } elsif($heap->{Data} =~ s,^([^<]+)</(\w+)>,,s) {  # Close Tag
    warn "Closing Tag : $2</$1>" if DEBUG;
    pop @{$heap->{tagstack}};
    $sender->postback($heap->{Tag})->('Close_Tag',$2,$1);
  } elsif($heap->{Data} =~ s,^([^<]+)<(\w+)>,<$2>,s) { # Inter Tag
    my $foo = $heap->{tagstack}[-1];
    warn "Inter Tag : <$foo>$1</$foo>" if DEBUG;
    $sender->postback($heap->{Tag})->('Inter Tag',$foo,$1);
  }
}

1;
__END__

=head1 NAME

POE::Component::MXML - Perl extension for parsing Minimal XML specs

=head1 SYNOPSIS

  use POE::Component::MXML;

=head1 DESCRIPTION

Stub documentation for POE::Component::MXML was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
