#!/usr/bin/perl
# Copyright (c) 2015-2016 by Pali <pali@cpan.org>

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Email-Address-XS.t'

#########################

use strict;
use warnings;

use Carp;
$Carp::Internal{'Test::Builder'} = 1;
$Carp::Internal{'Test::More'} = 1;

use Test::More tests => 15;

sub silent(&) {
	my ($code) = @_;
	local $SIG{__WARN__} = sub { };
	return $code->();
}

sub obj_to_hash {
	my ($self) = @_;
	my $hash = {};
	foreach ( qw(user host phrase comment) ) {
		$hash->{$_} = $self->{$_} if exists $self->{$_};
	}
	return $hash;
};

#########################

BEGIN {
	use_ok('Email::Address::XS', qw(parse_email_addresses parse_email_groups format_email_addresses format_email_groups));
};

#########################

require overload;
my $obj_to_str = overload::Method 'Email::Address::XS', '""';
my $obj_to_hash = \&obj_to_hash;

# set stringify operator for comparision used in is_deeply
{
	local $SIG{__WARN__} = sub { };
	overload::OVERLOAD 'Email::Address::XS', '""' => $obj_to_hash;
};

#########################

subtest 'test method new()' => sub {

	plan tests => 14;

	subtest 'test method new() without arguments' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new();
		is($address->phrase(), undef);
		is($address->user(), undef);
		is($address->host(), undef);
		is($address->address(), undef);
		is($address->comment(), undef);
		is($address->name(), '');
		is(silent { $address->format() }, '');
	};

	subtest 'test method new() with one argument' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new('Addressless Outer Party Member');
		is($address->phrase(), 'Addressless Outer Party Member');
		is($address->user(), undef);
		is($address->host(), undef);
		is($address->address(), undef);
		is($address->comment(), undef);
		is($address->name(), 'Addressless Outer Party Member');
		is(silent { $address->format() }, '');
	};

	subtest 'test method new() with two arguments as array' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(undef, 'user@oceania');
		is($address->phrase(), undef);
		is($address->user(), 'user');
		is($address->host(), 'oceania');
		is($address->address(), 'user@oceania');
		is($address->comment(), undef);
		is($address->name(), 'user');
		is($address->format(), 'user@oceania');
	};

	subtest 'test method new() with two arguments as hash' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(address => 'winston.smith@recdep.minitrue');
		is($address->phrase(), undef);
		is($address->user(), 'winston.smith');
		is($address->host(), 'recdep.minitrue');
		is($address->address(), 'winston.smith@recdep.minitrue');
		is($address->comment(), undef);
		is($address->name(), 'winston.smith');
		is($address->format(), 'winston.smith@recdep.minitrue');
	};

	subtest 'test method new() with two arguments as array' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(Julia => 'julia@ficdep.minitrue');
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->comment(), undef);
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue>');
	};

	subtest 'test method new() with three arguments' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new('Winston Smith', 'winston.smith@recdep.minitrue', 'Records Department');
		is($address->phrase(), 'Winston Smith');
		is($address->user(), 'winston.smith');
		is($address->host(), 'recdep.minitrue');
		is($address->address(), 'winston.smith@recdep.minitrue');
		is($address->comment(), 'Records Department');
		is($address->name(), 'Winston Smith');
		is($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)');
	};

	subtest 'test method new() with four arguments user & host as hash' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(user => 'julia', host => 'ficdep.minitrue');
		is($address->phrase(), undef);
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->comment(), undef);
		is($address->name(), 'julia');
		is($address->format(), 'julia@ficdep.minitrue');
	};

	subtest 'test method new() with four arguments phrase & address as hash' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->comment(), undef);
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue>');
	};

	subtest 'test method new() with four arguments as array' => sub {
		plan tests => 7;
		my $address = silent { Email::Address::XS->new('Julia', 'julia@ficdep.minitrue', 'Fiction Department', 'deprecated_original_string') };
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->comment(), 'Fiction Department');
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue> (Fiction Department)');
	};

	subtest 'test method new() with four arguments as hash (phrase is string "address")' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(phrase => 'address', address => 'user@oceania');
		is($address->phrase(), 'address');
		is($address->user(), 'user');
		is($address->host(), 'oceania');
		is($address->address(), 'user@oceania');
		is($address->comment(), undef);
		is($address->name(), 'address');
		is($address->format(), 'address <user@oceania>');
	};

	subtest 'test method new() with invalid email address' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(address => 'invalid_address');
		is($address->phrase(), undef);
		is($address->user(), undef);
		is($address->host(), undef);
		is($address->address(), undef);
		is($address->comment(), undef);
		is($address->name(), '');
		is(silent { $address->format() }, '');
	};

	subtest 'test method new() with empty strings for user and host and non empty for phrase' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(user => '', host => '', phrase => 'phrase');
		is($address->phrase(), 'phrase');
		is($address->user(), '');
		is($address->host(), '');
		is($address->address(), undef);
		is($address->comment(), undef);
		is($address->name(), 'phrase');
		is(silent { $address->format() }, '');
	};

	subtest 'test method new() with all named arguments' => sub {
		plan tests => 7;
		my $address = Email::Address::XS->new(phrase => 'Julia', user => 'julia', host => 'ficdep.minitrue', comment => 'Fiction Department');
		is($address->phrase(), 'Julia');
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
		is($address->comment(), 'Fiction Department');
		is($address->name(), 'Julia');
		is($address->format(), 'Julia <julia@ficdep.minitrue> (Fiction Department)');
	};

	subtest 'test method new() that address takes precedence over user and host' => sub {
		plan tests => 3;
		my $address = Email::Address::XS->new(user => 'winston.smith', host => 'recdep.minitrue', address => 'julia@ficdep.minitrue' );
		is($address->user(), 'julia');
		is($address->host(), 'ficdep.minitrue');
		is($address->address(), 'julia@ficdep.minitrue');
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

	plan tests => 20;

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
	is($address->user(), undef);
	is($address->host(), undef);

	is($address->address('julia@ficdep.minitrue'), 'julia@ficdep.minitrue');
	is($address->address('invalid_address'), undef);
	is($address->address(), undef);

};

#########################

subtest 'test method comment()' => sub {

	plan tests => 17;

	my $address = Email::Address::XS->new();
	is($address->comment(), undef);

	is($address->comment('Fiction Department'), 'Fiction Department');
	is($address->comment(), 'Fiction Department');

	is($address->comment('Records Department'), 'Records Department');
	is($address->comment(), 'Records Department');

	is($address->comment(undef), undef);
	is($address->comment(), undef);

	is($address->comment('(comment)'), '(comment)');
	is($address->comment(), '(comment)');

	is($address->comment('string (comment) string'), 'string (comment) string');
	is($address->comment(), 'string (comment) string');

	is($address->comment('string (comment (nested ()comment)another comment)()'), 'string (comment (nested ()comment)another comment)()');
	is($address->comment(), 'string (comment (nested ()comment)another comment)()');

	is($address->comment('string ((not balanced comment)'), undef);
	is($address->comment(), undef);

	is($address->comment('string )(()not balanced'), undef);
	is($address->comment(), undef);

};

#########################

subtest 'test method name()' => sub {

	plan tests => 14;

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

	$address->comment('Winston');
	is($address->name(), 'Winston');

	$address->phrase('Long phrase');
	is($address->name(), 'Long phrase');

	$address->phrase('Long phrase 2');
	is($address->name(), 'Long phrase 2');

	$address->user('user3');
	is($address->name(), 'Long phrase 2');

	$address->comment('winston');
	is($address->name(), 'Long phrase 2');

	$address->phrase(undef);
	is($address->name(), 'winston');

	$address->comment(undef);
	is($address->name(), 'user3');

	$address->address(undef);
	is($address->name(), '');

	$address->phrase('Long phrase 3');
	is($address->phrase(), 'Long phrase 3');

};

#########################

subtest 'test object stringify' => sub {

	plan tests => 5;

	# set correct stringify operator
	{
		local $SIG{__WARN__} = sub { };
		overload::OVERLOAD 'Email::Address::XS', '""' => $obj_to_str;
	}

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

	# revert back
	{
		local $SIG{__WARN__} = sub { };
		overload::OVERLOAD 'Email::Address::XS', '""' => $obj_to_hash;
	}
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

	plan tests => 5;

	is_deeply(
		[ silent { Email::Address::XS->parse() } ],
		[],
		'test method parse() without argument',
	);

	is_deeply(
		[ silent { Email::Address::XS->parse(undef) } ],
		[],
		'test method parse() with undef argument',
	);

	is_deeply(
		[ Email::Address::XS->parse('') ],
		[],
		'test method parse() on empty string',
	);

	is_deeply(
		[ silent { Email::Address::XS->parse('invalid_line') } ],
		[ Email::Address::XS->new(phrase => 'invalid_line') ],
		'test method parse() on invalid not parsable line',
	);

	is_deeply(
		[ Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'), Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'), Email::Address::XS->new(address => 'user@oceania') ],
		'test method parse() on string with valid addresses',
	);

};

#########################

subtest 'test method format_email_addresses()' => sub {

	plan tests => 6;

	is(
		format_email_addresses(),
		'',
		'test method format_email_addresses() with empty list of addresses',
	);

	is(
		silent { format_email_addresses('invalid string') },
		'',
		'test method format_email_addresses() with invalid string argument',
	);

	is(
		format_email_addresses(Email::Address::XS::Derived->new(user => 'user', host => 'host')),
		'user_derived_suffix@host',
		'test method format_email_addresses() with derived object class',
	);

	is(
		silent { format_email_addresses(Email::Address::XS::NotDerived->new(user => 'user', host => 'host')) },
		'',
		'test method format_email_addresses() with not derived object class',
	);

	is(
		silent { format_email_addresses(bless([], 'invalid_object_class')) },
		'',
		'test method format_email_addresses() with invalid object class',
	);

	is(
		format_email_addresses(
			Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
			Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania'),
			Email::Address::XS->new(address => 'user@oceania'),
			Email::Address::XS->new(phrase => 'Escape " also , characters ;', address => 'user2@oceania'),
			Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania'),
		),
		'"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, O\'Brien <o\'brien@thought.police.oceania>, "Mr. Charrington" <"charrington\"@\"shop"@thought.police.oceania>, "Emmanuel Goldstein" <goldstein@brotherhood.oceania>, user@oceania, "Escape \" also , characters ;" <user2@oceania>, "user5@oceania\" <user6@oceania> , \"" <user4@oceania>',
		'test method format_email_addresses() with list of different type of addresses',
	);

};

#########################

subtest 'test method parse_email_addresses()' => sub {

	plan tests => 21;

	is_deeply(
		[ silent { parse_email_addresses(undef) } ],
		[],
		'test method parse_email_addresses() with undef argument',
	);

	is_deeply(
		[ parse_email_addresses('') ],
		[],
		'test method parse_email_addresses() on empty string',
	);

	is_deeply(
		[ parse_email_addresses('incorrect') ],
		[ Email::Address::XS->new(phrase => 'incorrect') ],
		'test method parse_email_addresses() on incorrect string',
	);

	is_deeply(
		[ parse_email_addresses('Winston Smith <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with unquoted phrase',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with quoted phrase',
	);

	is_deeply(
		[ parse_email_addresses('winston.smith@recdep.minitrue') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with just address',
	);

	is_deeply(
		[ parse_email_addresses('winston.smith@recdep.minitrue (Winston Smith)') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue', comment => 'Winston Smith') ],
		'test method parse_email_addresses() on string with comment after address',
	);

	is_deeply(
		[ parse_email_addresses('<winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with just address in angle brackets',
	);

	is_deeply(
		[ parse_email_addresses('"user@oceania" : winston.smith@recdep.minitrue') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with character @ inside group name',
	);

	is_deeply(
		[ parse_email_addresses('"user@oceania" <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'user@oceania', address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with character @ inside phrase',
	);

	is_deeply(
		[ parse_email_addresses('"julia@outer\\"party"@ficdep.minitrue') ],
		[ Email::Address::XS->new(user => 'julia@outer"party', host => 'ficdep.minitrue') ],
		'test method parse_email_addresses() on string with quoted and escaped mailbox part of address',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>') ],
		[
			Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
		],
		'test method parse_email_addresses() on string with two items',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania') ],
		[
			Email::Address::XS->new('Winston Smith', 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new('Julia', 'julia@ficdep.minitrue'), Email::Address::XS->new(address => 'user@oceania'),
		],
		'test method parse_email_addresses() on string with three items',
	);

	is_deeply(
		[ parse_email_addresses('(leading comment)"Winston (Smith)" <winston.smith@recdep.minitrue(.oceania)> (comment after), Julia (Unknown) <julia(outer party)@ficdep.minitrue> (additional comment)') ],
		[
			Email::Address::XS->new(phrase => 'Winston (Smith)', address => 'winston.smith@recdep.minitrue', comment => 'comment after'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue', comment => 'additional comment'),
		],
		'test method parse_email_addresses() on string with a lots of comments',
	);

	is_deeply(
		[ parse_email_addresses('Winston Smith( <user@oceania>, Julia) <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with comma in comment',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" ( <user@oceania>, (Julia) <julia(outer(.)party)@ficdep.minitrue>, ) <winston.smith@recdep.minitrue>' ) ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test method parse_email_addresses() on string with nested comments',
	);

	is_deeply(
		[ parse_email_addresses('Winston Smith <winston   .smith  @  recdep(comment).      minitrue>' ) ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue', comment => 'comment') ],
		'test method parse_email_addresses() on string with obsolate white spaces',
	);

	is_deeply(
		[ parse_email_addresses("\302\257\302\257`\302\267.\302\245\302\253P\302\256\303\216\303\221\303\247\342\202\254\303\230fTh\342\202\254\303\220\303\205\302\256K\302\273\302\245.\302\267`\302\257\302\257 <email\@example.com>, \"(> \\\" \\\" <)                              ( ='o'= )                              (\\\")___(\\\")  sWeEtAnGeLtHePrInCeSsOfThEsKy\" <email2\@example.com>, \"(i)cRiStIaN(i)\" <email3\@example.com>, \"(S)MaNu_vuOLeAmMazZaReNimOe(*)MiAo(\@)\" <email4\@example.com>\n") ],
		[
			Email::Address::XS->new(phrase => "\302\257\302\257`\302\267.\302\245\302\253P\302\256\303\216\303\221\303\247\342\202\254\303\230fTh\342\202\254\303\220\303\205\302\256K\302\273\302\245.\302\267`\302\257\302\257", user => 'email', host => 'example.com'),
			Email::Address::XS->new(phrase => '(> " " <)                              ( =\'o\'= )                              (")___(")  sWeEtAnGeLtHePrInCeSsOfThEsKy', user => 'email2', host => 'example.com'),
			Email::Address::XS->new(phrase => '(i)cRiStIaN(i)', user => 'email3', host => 'example.com'),
			Email::Address::XS->new(phrase => '(S)MaNu_vuOLeAmMazZaReNimOe(*)MiAo(@)', user => 'email4', host => 'example.com'),
		],
		'test method parse_email_addresses() on CVE-2015-7686 string',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, O\'Brien <o\'brien@thought.police.oceania>, "Mr. Charrington" <"charrington\"@\"shop"@thought.police.oceania>, "Emmanuel Goldstein" <goldstein@brotherhood.oceania>, user@oceania, "Escape \" also , characters ;" <user2@oceania>, "user5@oceania\" <user6@oceania> , \"" <user4@oceania>') ],
		[
			Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
			Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania'),
			Email::Address::XS->new(address => 'user@oceania'),
			Email::Address::XS->new(phrase => 'Escape " also , characters ;', address => 'user2@oceania'),
			Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania'),
		],
		'test method parse_email_addresses() on string with lots of different types of addresses',
	);

	is_deeply(
		[ parse_email_addresses('winston.smith@recdep.minitrue', 'Email::Address::XS::Derived') ],
		[ bless({ phrase => undef, user => 'winston.smith', host => 'recdep.minitrue', comment => undef }, 'Email::Address::XS::Derived') ],
		'test method parse_email_addresses() with second derived class name argument',
	);

	is_deeply(
		[ silent { parse_email_addresses('winston.smith@recdep.minitrue', 'Email::Address::XS::NotDerived') } ],
		[],
		'test method parse_email_addresses() with second not derived class name argument',
	);

};

#########################

subtest 'test method format_email_groups()' => sub {

	plan tests => 13;

	my $undef = undef;

	my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
	my $julias_address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
	my $obriens_address = Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania');
	my $charringtons_address = Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania');
	my $goldstein_address = Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania');
	my $user_address = Email::Address::XS->new(address => 'user@oceania');
	my $user2_address = Email::Address::XS->new(phrase => 'Escape " also , characters', address => 'user2@oceania');
	my $user3_address = Email::Address::XS->new(address => 'user3@oceania');
	my $user4_address = Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania');

	my $derived_object = Email::Address::XS::Derived->new(user => 'user', host => 'host');
	my $not_derived_object = Email::Address::XS::NotDerived->new(user => 'user', host => 'host');

	my $nameless_group = '';
	my $brotherhood_group = 'Brotherhood';
	my $minitrue_group = 'Ministry of "Truth"';
	my $thoughtpolice_group = 'Thought Police';
	my $users_group = 'users@oceania';
	my $undisclosed_group = 'undisclosed-recipients';

	is(
		silent { format_email_groups('first', 'second', 'third') },
		undef,
		'test method format_email_groups() with odd number of arguments',
	);

	is(
		format_email_groups('name', undef),
		'name:;',
		'test method format_email_groups() with invalid type second argument (undef)',
	);

	is(
		silent { format_email_groups('name', 'string') },
		'name:;',
		'test method format_email_groups() with invalid type second argument (string)',
	);

	is(
		format_email_groups(),
		'',
		'test method format_email_groups() with empty list of groups',
	);

	is(
		format_email_groups($undef => []),
		'',
		'test method format_email_groups() with empty list of addresses in one undef group',
	);

	is(
		format_email_groups($undef => [ $user_address ]),
		'user@oceania',
		'test method format_email_groups() with one email address in undef group',
	);

	is(
		format_email_groups($nameless_group => [ $user_address ]),
		'"": user@oceania;',
		'test method format_email_groups() with one email address in nameless group',
	);

	is(
		format_email_groups($undisclosed_group => []),
		'undisclosed-recipients:;',
		'test method format_email_groups() with empty list of addresses in one named group',
	);

	is(
		format_email_groups($undef => [ $derived_object ]),
		'user_derived_suffix@host',
		'test method format_email_groups() with derived object class',
	);

	is(
		silent { format_email_groups($undef => [ $not_derived_object ]) },
		'',
		'test method format_email_groups() with not derived object class',
	);

	is(
		format_email_groups($brotherhood_group => [ $winstons_address, $julias_address ]),
		'Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;',
		'test method format_email_groups() with two addresses in one named group',
	);

	is(
		format_email_groups(
			$brotherhood_group => [ $winstons_address, $julias_address ],
			$undef => [ $user_address ]
		),
		'Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, user@oceania',
		'test method format_email_groups() with addresses in two groups',
	);

	is(
		format_email_groups(
			$minitrue_group => [ $winstons_address, $julias_address ],
			$thoughtpolice_group => [ $obriens_address, $charringtons_address ],
			$undef => [ $user_address, $user2_address ],
			$undisclosed_group => [],
			$undef => [ $user3_address ],
			$brotherhood_group => [ $goldstein_address ],
			$users_group => [ $user4_address ],
		),
		'"Ministry of \\"Truth\\"": "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, "Thought Police": O\'Brien <o\'brien@thought.police.oceania>, "Mr. Charrington" <"charrington\\"@\\"shop"@thought.police.oceania>;, user@oceania, "Escape \" also , characters" <user2@oceania>, undisclosed-recipients:;, user3@oceania, Brotherhood: "Emmanuel Goldstein" <goldstein@brotherhood.oceania>;, "users@oceania": "user5@oceania\\" <user6@oceania> , \\"" <user4@oceania>;',
		'test method format_email_groups() with different type of addresses in more groups',
	);

};

#########################

subtest 'test method parse_email_groups()' => sub {

	plan tests => 6;

	my $undef = undef;

	is_deeply(
		[ silent { parse_email_groups(undef) } ],
		[],
		'test method parse_email_groups() with undef argument',
	);

	is_deeply(
		[ parse_email_groups('') ],
		[],
		'test method parse_email_groups() on empty string',
	);

	is_deeply(
		[ parse_email_groups('incorrect') ],
		[
			$undef => [
				Email::Address::XS->new(phrase => 'incorrect'),
			],
		],
		'test method parse_email_groups() on incorrect string',
	);

	is_deeply(
		[ parse_email_groups('winston.smith@recdep.minitrue', 'Email::Address::XS::Derived') ],
		[
			$undef => [
				bless({ phrase => undef, user => 'winston.smith', host => 'recdep.minitrue', comment => undef }, 'Email::Address::XS::Derived'),
			],
		],
		'test method parse_email_groups() with second derived class name argument',
	);

	is_deeply(
		[ silent { parse_email_groups('winston.smith@recdep.minitrue', 'Email::Address::XS::NotDerived') } ],
		[],
		'test method parse_email_groups() with second not derived class name argument',
	);

	is_deeply(
		[ parse_email_groups('"Ministry of \\"Truth\\"": "Winston Smith" ( <user@oceania>, (Julia _ (Unknown)) <julia_(outer(.)party)@ficdep.minitrue>, ) <winston.smith@recdep.minitrue>, (leading comment) Julia <julia@ficdep.minitrue>;, "Thought Police" (group name comment) : O\'Brien <o\'brien@thought.police.oceania>, Mr. (c)Charrington <(mr.)"charrington\\"@\\"shop"@thought.police.oceania> (junk shop);, user@oceania (unknown_display_name in comment), "Escape \" also , characters" <user2@oceania>, undisclosed-recipients:;, user3@oceania (nested (comment)), Brotherhood(s):"Emmanuel Goldstein"<goldstein@brotherhood.oceania>; , "users@oceania" : "user5@oceania\\" <user6@oceania> , \\"" <user4@oceania>;, "":;' ) ],
		[
			'Ministry of "Truth"' => [
				Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
				Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
			],
			'Thought Police' => [
				Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania'),
				Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania', comment => 'junk shop'),
			],
			$undef => [
				Email::Address::XS->new(address => 'user@oceania', comment => 'unknown_display_name in comment'),
				Email::Address::XS->new(phrase => 'Escape " also , characters', address => 'user2@oceania'),
			],
			'undisclosed-recipients' => [],
			$undef => [
				Email::Address::XS->new(address => 'user3@oceania', comment => 'nested (comment)'),
			],
			Brotherhood => [
				Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania'),
			],
			'users@oceania' => [
				Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania'),
			],
			"" => [],
		],
	);

};

package Email::Address::XS::Derived;

use base 'Email::Address::XS';

sub user {
	my ($self, @args) = @_;
	$args[0] .= "_derived_suffix" if @args and defined $args[0];
	return $self->SUPER::user(@args);
}

package Email::Address::XS::NotDerived;

sub new {
	return bless {};
}

sub user {
	return 'not_derived';
}
