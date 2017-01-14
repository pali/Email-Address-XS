#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Email::Address::XS',
	VERSION_FROM	=> 'lib/Email/Address/XS.pm',
	ABSTRACT_FROM	=> 'lib/Email/Address/XS.pm',
	AUTHOR		=> 'Pali <pali@cpan.org>',
	OBJECT		=> '$(O_FILES)',
	NORECURS	=> 1,
	LICENSE		=> 'perl_5',
	MIN_PERL_VERSION	=> '5.6.0',
	PREREQ_PM	=> {
		'strict' => 0,
		'warnings' => 0,
		'base' => 0,
		'overload' => 0,
		'Carp' => 0,
		'Exporter' => 0,
		'XSLoader' => 0,
	},
	TEST_REQUIRES => {
		'Test::More' => 0,
	},
);
