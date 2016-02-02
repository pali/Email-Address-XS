# Copyright (c) 2015-2016 by Pali <pali@cpan.org>

package Email::Address::XS;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

use base 'Exporter';
our @EXPORT_OK = qw(parse_email_addresses parse_email_groups format_email_addresses format_email_groups);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 NAME

Email::Address::XS - RFC 2822 Parse and format email groups or addresses

=head1 SYNOPSIS

  use Email::Address::XS;

  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', user => 'winston.smith', host => 'recdep.minitrue');
  print $winstons_address->address();

  my $julias_address = Email::Address::XS->new('Julia', 'julia@ficdep.minitrue');
  print $julias_address->format();

  my $user_address = Email::Address::XS->new(address => 'user@oceania');
  print $user_address->user();


  use Email::Address::XS qw(format_email_addresses format_email_groups parse_email_addresses parse_email_groups);
  my $undef = undef;

  my $addresses_string = format_email_addresses($winstons_address, $julias_address, $user_address);
  print $addresses_string;

  my @addresses = parse_email_addresses($addresses_string);
  print 'address: ' . $_->address() . '\n' foreach @addresses;

  my $groups_string = format_email_groups('Brotherhood' => [ $winstons_address, $julias_address ], $undef => [ $user_address ]);
  print $groups_string;

  my @groups = parse_email_groups($groups_string);

=head1 DESCRIPTION

This module implements L<RFC 2822|https://tools.ietf.org/html/rfc2822>
parser and formatter of email groups or addresses. It parses input
string from email headers which contain a list of email addresses or
a group of email addresses (like From, To, Cc, Bcc, Reply-To, Sender,
...). Also it can generate string values for those headers from list
of email addresses objects.

Parser and formatter functionality are implemented in XS and use
shared code from Dovecot IMAP server.

It is a drop-in replacement for L<the Email::Address module|Email::Address>
which has several security issues. E.g. issue L<CVE-2015-7686 (Algorithmic complexity vulnerability)|https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-7686>,
which allows remote attackers to cause denial of service, is still
present in L<Email::Address|Email::Address> version 1.908.

Email::Address::XS module was created to finally fix CVE-2015-7686.

Existing applications that use Email::Address module could be easily
switched to Email::Address::XS module. In most cases only changing
C<use Email::Address> to C<use Email::Address::XS> and replacing every
C<Email::Address> occurrence with C<Email::Address::XS> is sufficient.

So unlike L<Email::Address|Email::Address>, this module does not use
regular expressions for parsing but instead native XS implementation
parses input string sequentially according to RFC 2822 grammar.

Additionally it has support also for named groups and so can be use
instead of L<the Email::Address::List module|Email::Address::List>.

=head2 EXPORT

None by default. Exportable methods are:
C<parse_email_addresses>,
C<parse_email_groups>,
C<format_email_addresses>,
C<format_email_groups>
.

=head2 Exportable Methods

=over 4

=item format_email_addresses

  use Email::Address::XS qw(format_email_addresses);

  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston@recdep.minitrue');
  my $julias_address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
  my @addresses = ( $winstons_address, $julias_address );
  my $string = format_email_addresses(@addresses);
  print $string;

Takes list of email address objects and returns one formatted string
of those email addresses.

=cut

sub format_email_addresses {
	my (@args) = @_;
	return format_email_groups(undef, \@args);
}

=item format_email_groups

  use Email::Address::XS qw(format_email_groups);
  my $undef = undef;

  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', user => 'winston.smith', host => 'recdep.minitrue');
  my $julias_address = Email::Address::XS->new('Julia', 'julia@ficdep.minitrue');
  my $user_address = Email::Address::XS->new(address => 'user@oceania');

  my $groups_string = format_email_groups('Brotherhood' => [ $winstons_address, $julias_address ], $undef => [ $user_address ]);
  print $groups_string;

  my $undisclosed_string = format_email_groups('undisclosed-recipients' => []);
  print $undisclosed_string;

Like C<format_email_addresses> but this method takes pairs which
consist of a group display name and a reference to address list. If a
group is not undef then address list is formatted inside named group.

=item parse_email_addresses

  use Email::Address::XS qw(parse_email_addresses);

  my $string = '"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania';
  my @addresses = parse_email_addresses($string);
  # @addresses now contains three Email::Address::XS objects, one for each address

Parses input string and returns list of Email::Address::XS objects.
Optional second string argument specifies class name for blessing new
objects.

=cut

sub parse_email_addresses {
	my (@args) = @_;
	my $t = 1;
	return map { @{$_} } grep { $t ^= 1 } parse_email_groups(@args);
}

=item parse_email_groups

  use Email::Address::XS qw(parse_email_groups);
  my $undef = undef;

  my $string = 'Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, user@oceania, undisclosed-recipients:;';
  my @groups = parse_email_groups($string);
  # @groups now contains list ( 'Brotherhood' => [ $winstons_object, $julias_object ], $undef => [ $user_object ], 'undisclosed-recipients' => [])

Like C<parse_email_addresses> but this method returns a list of pairs:
a group display name and a reference to list of addresses which
belongs to that named group. Undef value for group means that
following list of addresses is not inside any named group. The output
is in same format as the input for method C<format_email_groups>.
Function preserves order of groups and does not do any de-duplication
or merging.

=back

=head2 Class Methods

=over 4

=item new

  my $empty_address = Email::Address::XS->new();
  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', user => 'winston.smith', host => 'recdep.minitrue');
  my $julias_address = Email::Address::XS->new('Julia', 'julia@ficdep.minitrue');
  my $user_address = Email::Address::XS->new(address => 'user@oceania');
  my $only_name = Email::Address::XS->new(phrase => 'Name');

Constructs and returns a new C<Email::Address::XS> object. Takes either
named list of arguments: phrase, address, user, host. Argument address
takes precedence before user and host.

Old syntax L<from the Email::Address module|Email::Address/new> is
supported too. Takes one to four positional arguments: phrase, address
comment, and original string. Arguments comment and original are
deprecated and ignored. Their usage throw warnings.

=cut

sub new {
	my ($class, @args) = @_;

	my $is_hash;
	if ( scalar @args == 2 ) {
		$is_hash = 1 if defined $args[0] and $args[0] eq 'address';
	} elsif ( scalar @args == 4 ) {
		my %args = @args;
		$is_hash = 1 if exists $args{address};
		$is_hash = 1 if exists $args{user} and exists $args{host};
	} elsif ( scalar @args != 1 and scalar @args != 3 ) {
		$is_hash = 1;
	}

	my %args;
	if ( $is_hash ) {
		%args = @args;
	} else {
		carp 'Argument comment is deprecated and ignored' if scalar @args > 3;
		carp 'Argument original is deprecated and ignored' if scalar @args > 2;
		$args{address} = $args[1] if scalar @args > 1;
		$args{phrase} = $args[0] if scalar @args > 0;
	}

	my $self = bless {}, $class;

	$self->phrase($args{phrase});

	if ( exists $args{address} ) {
		$self->address($args{address});
	} else {
		$self->user($args{user});
		$self->host($args{host});
	}

	return $self;
}

=back

=head2 Object Methods

=over 4

=item format

  my $string = $address->format();

Returns formatted email address as a string.

=cut

sub format {
	my ($self) = @_;
	return format_email_addresses($self);
}

=item phrase

  my $phrase = $address->phrase();
  $address->phrase('Winston Smith');

Accessor and mutator for the phrase (display name) portion of an address.

=cut

sub phrase {
	my ($self, @args) = @_;
	return $self->{phrase} unless @args;
	return $self->{phrase} = $args[0];
}

=item user

  my $user = $address->user();
  $address->user('winston.smith');

Accessor and mutator for the unescaped user portion of an address's address.

=cut

sub user {
	my ($self, @args) = @_;
	return $self->{user} unless @args;
	delete $self->{cached_address} if exists $self->{cached_address};
	return $self->{user} = $args[0];
}

=item host

  my $host = $address->host();
  $address->host('recdep.minitrue');

Accessor and mutator for the host portion of an address's address.

=cut

sub host {
	my ($self, @args) = @_;
	return $self->{host} unless @args;
	delete $self->{cached_address} if exists $self->{cached_address};
	return $self->{host} = $args[0];
}

=item address

  my $string_address = $address->address();
  $address->address('winston.smith@recdep.minitrue');

Accessor and mutator for the escaped address portion of an address.

Internally this module stores user and host portion of an address's
address separately. For composing full address portion this method
uses C<format> and for dividing uses C<parse_email_addresses>.

=cut

sub address {
	my ($self, @args) = @_;
	my $user;
	my $host;
	if ( @args ) {
		my ($address) = defined $args[0] ? parse_email_addresses($args[0]) : ();
		if ( defined $address ) {
			$user = $self->user($address->user());
			$host = $self->host($address->host());
		} else {
			$self->user(undef);
			$self->host(undef);
		}
	} else {
		return $self->{cached_address} if exists $self->{cached_address};
		$user = $self->user();
		$host = $self->host();
	}
	if ( defined $user and defined $host ) {
		my $address = bless { user => $user, host => $host };
		return $self->{cached_address} = $address->format();
	} else {
		return $self->{cached_address} = undef;
	}
}

=item name

  my $name = $address->name();

This method tries to return the name belonging to the address. It
returns either C<phrase> or C<user> portion of C<address> or empty
string. But never returns undef.

=cut

sub name {
	my ($self) = @_;
	my $phrase = $self->phrase();
	return $phrase if defined $phrase and length $phrase;
	my $user = $self->user();
	return $user if defined $user and length $user;
	return '';
}

=back

=head2 Overloaded Operators

=over 4

=item stringify

  my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
  print "Winston's address is $address.";
  # Winston's address is "Winston Smith" <winston.smith@recdep.minitrue>.

Objects stringify to C<format>.

=cut

our $STRINGIFY; # deprecated

use overload '""' => sub {
	my ($self) = @_;
	return $self->format() unless defined $STRINGIFY;
	carp 'Variable $Email::Address::XS::STRINGIFY is deprecated; subclass instead';
	return $self->can($STRINGIFY)->($self);
};

=back

=head2 Deprecated Methods and Variables

For compatibility with L<the Email::Address module|Email::Address>
there are defined some deprecated methods and variables. Do not use
them in new code. Their usage throw warnings.

Altering deprecated variable C<$Email:Address::XS::STRINGIFY> changes
method which is called for objects stringification.

Deprecated cache methods C<purge_cache>, C<disable_cache> and
C<enable_cache> are noop do nothing.

=cut

sub purge_cache {
	carp 'Method purge_cache is deprecated and does nothing';
}

sub disable_cache {
	carp 'Method disable_cache is deprecated and does nothing';
}

sub enable_cache {
	carp 'Method enable_cache is deprecated and does nothing';
}

=pod

Deprecated class method C<parse> takes two arguments class name and
input string. It just calls method C<parse_email_addresses>. Usage is
same as in old L<Email::Address module|Email::Address/parse>.

There is also method C<comment> which always returns undef and method
C<original> which returns C<address>. Do not use them.

=cut

sub parse {
	my ($class, $string) = @_;
	return parse_email_addresses($string, $class);
}

sub comment {
	carp 'Method comment is deprecated and always returns undef';
	return undef;
}

sub original {
	my ($self) = @_;
	carp 'Method original is deprecated and returns address';
	return $self->address();
}

=head1 SEE ALSO

L<RFC 822|https://tools.ietf.org/html/rfc822>,
L<RFC 2822|https://tools.ietf.org/html/rfc2822>,
L<Email::Address>,
L<Email::Address::List>,
L<Email::AddressParser>

=head1 AUTHOR

Pali E<lt>pali@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Pali E<lt>pali@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.2 or,
at your option, any later version of Perl 5 you may have available.

Dovecot parser is licensed under The MIT License and copyrighted by
Dovecot authors.

=cut

1;
