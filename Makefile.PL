#!/usr/bin/perl
# $File: //member/autrijus/GeekCode/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 699 $ $DateTime: 2002/08/17 22:01:07 $

use ExtUtils::MakeMaker;
require 5.005;

WriteMakefile (
    NAME         => 'Convert::GeekCode',
    DISTNAME     => 'Convert-GeekCode',
    ABSTRACT     => 'Convert and generate geek codes sequences',
    AUTHOR       => 'Autrijus Tang (autrijus@autrijus.org)',
    VERSION_FROM => 'GeekCode.pm',
    EXE_FILES    => [ <bin/*> ],

    PREREQ_PM	 => {
	'Text::Wrap'	=> '0',
	'YAML'	 	=> '0',
    },
    dist         => {
	COMPRESS => 'gzip -9',
	SUFFIX => 'gz',
    },
);
