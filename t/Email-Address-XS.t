#!/usr/bin/perl
# Copyright (c) 2015-2016 by Pali <pali@cpan.org>

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Email-Address-XS.t'

#########################

use strict;
use warnings;

use Test::More tests => 14;

sub silent(&) {
	my ($code) = @_;
	local $SIG{__WARN__} = sub { };
	return $code->();
}

#########################

BEGIN {
	use_ok('Email::Address::XS', qw(parse_email_addresses parse_email_groups format_email_addresses format_email_groups));
};

#########################

subtest 'test method new()' => sub {

	plan tests => 10;

	subtest 'test method new() without arguments' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new();
		is($address->phrase(), undef);
		is($address->user(), undef);
		is($address->host(), undef);
		is($address->address(), undef);
		is($address->name(), '');
		is(silent { $address->format() }, '');
	};

	subtest 'test method new() with one argument' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new('Addressless Outer Party Member');
		is($address->phrase(), 'Addressless Outer Party Member');
		is($address->user(), undef);
		is($address->host(), undef);
		is($address->address(), undef);
		is($address->name(), 'Addressless Outer Party Member');
		is(silent { $address->format() }, '');
	};

	subtest 'test method new() with two arguments as array' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new(undef, 'user@oceania');
		is($address->phrase(), undef);
		is($address->user(), 'user');
		is($address->host(), 'oceania');
		is($address->address(), 'user@oceania');
		is($address->name(), 'user');
		is($address->format(), 'user@oceania');
	};

	subtest 'test method new() with two arguments as hash' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new(address => 'winston.smith@recdep.minitrue');
		is($address->phrase(), undef);
		is($address->user(), 'winston.smith');
		is($address->host(), 'recdep.minitrue');
		is($address->address(), 'winston.smith@recdep.minitrue');
		is($address->name(), 'winston.smith');
		is($address->format(), 'winston.smith@recdep.minitrue');
	};

	subtest 'test method new() with two arguments as array' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new(Julia => 'julia@ficdep.minitrue');
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue>');
	};

	subtest 'test method new() with three arguments' => sub {
		plan tests => 6;
		my $address = silent { Email::Address::XS->new('Winston Smith', 'winston.smith@recdep.minitrue', 'deprecated_original_string') };
		is($address->phrase(), 'Winston Smith');
		is($address->user(), 'winston.smith');
		is($address->host(), 'recdep.minitrue');
		is($address->address(), 'winston.smith@recdep.minitrue');
		is($address->name(), 'Winston Smith');
		is($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue>');
	};

	subtest 'test method new() with four arguments user & host as hash' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new(user => 'julia', host => 'ficdep.minitrue');
		is($address->phrase(), undef);
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->name(), 'julia');
		is($address->format(), 'julia@ficdep.minitrue');
	};

	subtest 'test method new() with four arguments phrase & address as hash' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue>');
	};

	subtest 'test method new() with four arguments as array' => sub {
		plan tests => 6;
		my $address = silent { Email::Address::XS->new('Julia', 'julia@ficdep.minitrue', 'deprecated_original_string', 'deprecated_comment_string') };
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue>');
	};

	subtest 'test method new() with four arguments as hash (phrase is string "address")' => sub {
		plan tests => 6;
		my $address = Email::Address::XS->new(phrase => 'address', address => 'user@oceania');
		is($address->phrase(), 'address');
		is($address->user(), 'user');
		is($address->host(), 'oceania');
		is($address->address(), 'user@oceania');
		is($address->name(), 'address');
		is($address->format(), 'address <user@oceania>');
	};

};

#########################

subtest 'test method phrase()' => sub {

	plan tests => 7;

	my $address = Email::Address::XS->new();
	is($address->phrase(), undef);

	is($address->phrase('Winston Smith'), 'Winston Smith');
	is($address->phrase(), 'Winston Smith');

	is($address->phrase('Julia'), 'Julia');
	is($address->phrase(), 'Julia');

	is($address->phrase(undef), undef);
	is($address->phrase(), undef);

};

#########################

subtest 'test method user()' => sub {

	plan tests => 7;

	my $address = Email::Address::XS->new();
	is($address->user(), undef);

	is($address->user('winston'), 'winston');
	is($address->user(), 'winston');

	is($address->user('julia'), 'julia');
	is($address->user(), 'julia');

	is($address->user(undef), undef);
	is($address->user(), undef);

};

#########################

subtest 'test method host()' => sub {

	plan tests => 7;

	my $address = Email::Address::XS->new();
	is($address->host(), undef);

	is($address->host('eurasia'), 'eurasia');
	is($address->host(), 'eurasia');

	is($address->host('eastasia'), 'eastasia');
	is($address->host(), 'eastasia');

	is($address->host(undef), undef);
	is($address->host(), undef);

};

#########################

subtest 'test method address()' => sub {

	plan tests => 15;

	my $address = Email::Address::XS->new();
	is($address->address(), undef);

	is($address->address('winston.smith@recdep.minitrue'), 'winston.smith@recdep.minitrue');
	is($address->address(), 'winston.smith@recdep.minitrue');
	is($address->user(), 'winston.smith');
	is($address->host(), 'recdep.minitrue');

	is($address->user('julia@outer"party'), 'julia@outer"party');
	is($address->user(), 'julia@outer"party');
	is($address->host(), 'recdep.minitrue');
	is($address->address(), '"julia@outer\\"party"@recdep.minitrue');

	is($address->address('julia@ficdep.minitrue'), 'julia@ficdep.minitrue');
	is($address->address(), 'julia@ficdep.minitrue');
	is($address->user(), 'julia');
	is($address->host(), 'ficdep.minitrue');

	is($address->address(undef), undef);
	is($address->address(), undef);

};

#########################

subtest 'test method name()' => sub {

	plan tests => 11;

	my $address = Email::Address::XS->new();
	is($address->name(), '');

	$address->user('user1');
	is($address->name(), 'user1');

	$address->user('user2');
	is($address->name(), 'user2');

	$address->host('host');
	is($address->name(), 'user2');

	$address->address('winston.smith@recdep.minitrue');
	is($address->name(), 'winston.smith');

	$address->phrase('Long phrase');
	is($address->name(), 'Long phrase');

	$address->phrase('Long phrase 2');
	is($address->name(), 'Long phrase 2');

	$address->user('user3');
	is($address->name(), 'Long phrase 2');

	$address->phrase(undef);
	is($address->name(), 'user3');

	$address->address(undef);
	is($address->name(), '');

	$address->phrase('Long phrase 3');
	is($address->phrase(), 'Long phrase 3');

};

#########################

subtest 'test object stringify' => sub {

	plan tests => 5;

	my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
	is("$address", '"Winston Smith" <winston.smith@recdep.minitrue>');

	$address->phrase('Winston');
	is("$address", 'Winston <winston.smith@recdep.minitrue>');

	$address->address('winston@recdep.minitrue');
	is("$address", 'Winston <winston@recdep.minitrue>');

	$address->phrase(undef);
	is("$address", 'winston@recdep.minitrue');

	$address->address(undef);
	is(silent { "$address" }, '');

};

#########################

subtest 'test method format()' => sub {

	plan tests => 5;

	my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
	is($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue>');

	$address->phrase('Julia');
	is($address->format(), 'Julia <winston.smith@recdep.minitrue>');

	$address->address('julia@ficdep.minitrue');
	is($address->format(), 'Julia <julia@ficdep.minitrue>');

	$address->phrase(undef);
	is($address->format(), 'julia@ficdep.minitrue');

	$address->address(undef);
	is(silent { $address->format() }, '');

};

#########################

subtest 'test method parse()' => sub {

	plan tests => 6;

	subtest 'test method parse() on string with unquoted phrase' => sub {
		plan tests => 1;
		my @addresses = silent { Email::Address::XS->parse('Winston Smith <winston.smith@recdep.minitrue>') };
		is_deeply(\@addresses, [ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ]);
	};

	subtest 'test method parse() on string with quoted phrase' => sub {
		plan tests => 1;
		my @addresses = silent { Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue>') };
		is_deeply(\@addresses, [ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ]);
	};

	subtest 'test method parse() on string with just address' => sub {
		plan tests => 1;
		my @addresses = silent { Email::Address::XS->parse('winston.smith@recdep.minitrue') };
		is_deeply(\@addresses, [ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ]);
	};

	subtest 'test method parse() on string with just address in angle brackets' => sub {
		plan tests => 1;
		my @addresses = silent { Email::Address::XS->parse('<winston.smith@recdep.minitrue>') };
		is_deeply(\@addresses, [ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ]);
	};

	subtest 'test method parse() on string with quoted and escaped mailbox part of address' => sub {
		plan tests => 1;
		my @addresses = silent { Email::Address::XS->parse('"julia@outer\\"party"@ficdep.minitrue') };
		is_deeply(\@addresses, [ Email::Address::XS->new(user => 'julia@outer"party', host => 'ficdep.minitrue') ]);
	};

	subtest 'test method parse() for string with two entries' => sub {
		plan tests => 1;
		my @addresses = silent { Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue>, "Julia" <julia@ficdep.minitrue>') };
		is_deeply(\@addresses, [ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'), Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue') ]);
	};

};

#########################

subtest 'test method format_email_addresses()' => sub {

	plan skip_all => 'TODO';

};

#########################

subtest 'test method parse_email_addresses()' => sub {

	plan skip_all => 'TODO';

};

#########################

subtest 'test method format_email_groups()' => sub {

	plan skip_all => 'TODO';

};

#########################

subtest 'test method parse_email_groups()' => sub {

	plan skip_all => 'TODO';

};
