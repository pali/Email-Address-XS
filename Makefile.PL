#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Email::Address::XS',
	VERSION_FROM	=> 'lib/Email/Address/XS.pm',
	ABSTRACT_FROM	=> 'lib/Email/Address/XS.pm',
	AUTHOR		=> 'Pali <pali@cpan.org>',
	OBJECT		=> '$(O_FILES)',
	NORECURS	=> 1,
);
