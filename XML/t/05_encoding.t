#!/usr/bin/perl -w
########################################################################
# test.pl - test script for XML::Writer::Encoding module.
# Copyright (c) 1999 by Megginson Technologies.
# Copyright (c) 2003 Ed Avis <ed@membled.com>
# Copyright (c) 2004-2010 Joseph Walton <joe@kafsemo.org>
# Redistribution and use in source and compiled forms, with or without
# modification, are permitted under any circumstances.  No warranty.
########################################################################

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 05_encoding.t'

use strict;

use Errno;

use Test::More(tests => 178);

# Catch warnings
my $warning;

$SIG{__WARN__} = sub {
	($warning) = @_ unless ($warning);
};

sub wasNoWarning($)
{
	my ($reason) = @_;

	if (!ok(!$warning, $reason)) {
		diag($warning);
	}
}

# Constants for Unicode support
my $unicodeSkipMessage = 'Unicode only supported with Perl >= 5.8.1';
my $htmlSkipMessage = 'HTML::Entities not available';
my $xmlSkipMessage = 'XML::Entities::Data not available';

sub isUnicodeSupported()
{
	return $] >= 5.008001;
}

require XML::Writer;
require XML::Writer::Encoding;

sub isHTMLEntitiesAvailable()
{
#	eval {require HTML::Entity;}; # Deliberate typo
	eval {require HTML::Entities;};
}

sub isXMLEntitiesDataAvailable() {
#	eval {require XML::Entity::Data;}; # Deliberate typo
	eval {require XML::Entities::Data;};
}

SKIP: {
	skip "Perls before 5.6 always warn when loading XML::Writer", 1 if $] <=
	5.006;

	wasNoWarning('Loading XML::Writer should not result in warnings');
}

use IO::File;

# The XML::Writer that will be used
my $w;

my $outputFile = IO::File->new_tmpfile or die "Unable to create temporary file: $!";

# Output from HTML::Entities mapping, interpolated in results as needed
my $html_internal_entities = <<'EOS';
 <!ENTITY quot     "&#x0022;" >
 <!ENTITY amp      "&#x0026;" >
 <!ENTITY lt       "&#x003C;" >
 <!ENTITY gt       "&#x003E;" >
 <!ENTITY nbsp     "&#x00A0;" >
 <!ENTITY iexcl    "&#x00A1;" >
 <!ENTITY cent     "&#x00A2;" >
 <!ENTITY pound    "&#x00A3;" >
 <!ENTITY curren   "&#x00A4;" >
 <!ENTITY yen      "&#x00A5;" >
 <!ENTITY brvbar   "&#x00A6;" >
 <!ENTITY sect     "&#x00A7;" >
 <!ENTITY uml      "&#x00A8;" >
 <!ENTITY copy     "&#x00A9;" >
 <!ENTITY ordf     "&#x00AA;" >
 <!ENTITY laquo    "&#x00AB;" >
 <!ENTITY not      "&#x00AC;" >
 <!ENTITY shy      "&#x00AD;" >
 <!ENTITY reg      "&#x00AE;" >
 <!ENTITY macr     "&#x00AF;" >
 <!ENTITY deg      "&#x00B0;" >
 <!ENTITY plusmn   "&#x00B1;" >
 <!ENTITY sup2     "&#x00B2;" >
 <!ENTITY sup3     "&#x00B3;" >
 <!ENTITY acute    "&#x00B4;" >
 <!ENTITY micro    "&#x00B5;" >
 <!ENTITY para     "&#x00B6;" >
 <!ENTITY middot   "&#x00B7;" >
 <!ENTITY cedil    "&#x00B8;" >
 <!ENTITY sup1     "&#x00B9;" >
 <!ENTITY ordm     "&#x00BA;" >
 <!ENTITY raquo    "&#x00BB;" >
 <!ENTITY frac14   "&#x00BC;" >
 <!ENTITY frac12   "&#x00BD;" >
 <!ENTITY frac34   "&#x00BE;" >
 <!ENTITY iquest   "&#x00BF;" >
 <!ENTITY Agrave   "&#x00C0;" >
 <!ENTITY Aacute   "&#x00C1;" >
 <!ENTITY Acirc    "&#x00C2;" >
 <!ENTITY Atilde   "&#x00C3;" >
 <!ENTITY Auml     "&#x00C4;" >
 <!ENTITY Aring    "&#x00C5;" >
 <!ENTITY AElig    "&#x00C6;" >
 <!ENTITY Ccedil   "&#x00C7;" >
 <!ENTITY Egrave   "&#x00C8;" >
 <!ENTITY Eacute   "&#x00C9;" >
 <!ENTITY Ecirc    "&#x00CA;" >
 <!ENTITY Euml     "&#x00CB;" >
 <!ENTITY Igrave   "&#x00CC;" >
 <!ENTITY Iacute   "&#x00CD;" >
 <!ENTITY Icirc    "&#x00CE;" >
 <!ENTITY Iuml     "&#x00CF;" >
 <!ENTITY ETH      "&#x00D0;" >
 <!ENTITY Ntilde   "&#x00D1;" >
 <!ENTITY Ograve   "&#x00D2;" >
 <!ENTITY Oacute   "&#x00D3;" >
 <!ENTITY Ocirc    "&#x00D4;" >
 <!ENTITY Otilde   "&#x00D5;" >
 <!ENTITY Ouml     "&#x00D6;" >
 <!ENTITY times    "&#x00D7;" >
 <!ENTITY Oslash   "&#x00D8;" >
 <!ENTITY Ugrave   "&#x00D9;" >
 <!ENTITY Uacute   "&#x00DA;" >
 <!ENTITY Ucirc    "&#x00DB;" >
 <!ENTITY Uuml     "&#x00DC;" >
 <!ENTITY Yacute   "&#x00DD;" >
 <!ENTITY THORN    "&#x00DE;" >
 <!ENTITY szlig    "&#x00DF;" >
 <!ENTITY agrave   "&#x00E0;" >
 <!ENTITY aacute   "&#x00E1;" >
 <!ENTITY acirc    "&#x00E2;" >
 <!ENTITY atilde   "&#x00E3;" >
 <!ENTITY auml     "&#x00E4;" >
 <!ENTITY aring    "&#x00E5;" >
 <!ENTITY aelig    "&#x00E6;" >
 <!ENTITY ccedil   "&#x00E7;" >
 <!ENTITY egrave   "&#x00E8;" >
 <!ENTITY eacute   "&#x00E9;" >
 <!ENTITY ecirc    "&#x00EA;" >
 <!ENTITY euml     "&#x00EB;" >
 <!ENTITY igrave   "&#x00EC;" >
 <!ENTITY iacute   "&#x00ED;" >
 <!ENTITY icirc    "&#x00EE;" >
 <!ENTITY iuml     "&#x00EF;" >
 <!ENTITY eth      "&#x00F0;" >
 <!ENTITY ntilde   "&#x00F1;" >
 <!ENTITY ograve   "&#x00F2;" >
 <!ENTITY oacute   "&#x00F3;" >
 <!ENTITY ocirc    "&#x00F4;" >
 <!ENTITY otilde   "&#x00F5;" >
 <!ENTITY ouml     "&#x00F6;" >
 <!ENTITY divide   "&#x00F7;" >
 <!ENTITY oslash   "&#x00F8;" >
 <!ENTITY ugrave   "&#x00F9;" >
 <!ENTITY uacute   "&#x00FA;" >
 <!ENTITY ucirc    "&#x00FB;" >
 <!ENTITY uuml     "&#x00FC;" >
 <!ENTITY yacute   "&#x00FD;" >
 <!ENTITY thorn    "&#x00FE;" >
 <!ENTITY yuml     "&#x00FF;" >
 <!ENTITY OElig    "&#x0152;" >
 <!ENTITY oelig    "&#x0153;" >
 <!ENTITY Scaron   "&#x0160;" >
 <!ENTITY scaron   "&#x0161;" >
 <!ENTITY Yuml     "&#x0178;" >
 <!ENTITY fnof     "&#x0192;" >
 <!ENTITY circ     "&#x02C6;" >
 <!ENTITY tilde    "&#x02DC;" >
 <!ENTITY Alpha    "&#x0391;" >
 <!ENTITY Beta     "&#x0392;" >
 <!ENTITY Gamma    "&#x0393;" >
 <!ENTITY Delta    "&#x0394;" >
 <!ENTITY Epsilon  "&#x0395;" >
 <!ENTITY Zeta     "&#x0396;" >
 <!ENTITY Eta      "&#x0397;" >
 <!ENTITY Theta    "&#x0398;" >
 <!ENTITY Iota     "&#x0399;" >
 <!ENTITY Kappa    "&#x039A;" >
 <!ENTITY Lambda   "&#x039B;" >
 <!ENTITY Mu       "&#x039C;" >
 <!ENTITY Nu       "&#x039D;" >
 <!ENTITY Xi       "&#x039E;" >
 <!ENTITY Omicron  "&#x039F;" >
 <!ENTITY Pi       "&#x03A0;" >
 <!ENTITY Rho      "&#x03A1;" >
 <!ENTITY Sigma    "&#x03A3;" >
 <!ENTITY Tau      "&#x03A4;" >
 <!ENTITY Upsilon  "&#x03A5;" >
 <!ENTITY Phi      "&#x03A6;" >
 <!ENTITY Chi      "&#x03A7;" >
 <!ENTITY Psi      "&#x03A8;" >
 <!ENTITY Omega    "&#x03A9;" >
 <!ENTITY alpha    "&#x03B1;" >
 <!ENTITY beta     "&#x03B2;" >
 <!ENTITY gamma    "&#x03B3;" >
 <!ENTITY delta    "&#x03B4;" >
 <!ENTITY epsilon  "&#x03B5;" >
 <!ENTITY zeta     "&#x03B6;" >
 <!ENTITY eta      "&#x03B7;" >
 <!ENTITY theta    "&#x03B8;" >
 <!ENTITY iota     "&#x03B9;" >
 <!ENTITY kappa    "&#x03BA;" >
 <!ENTITY lambda   "&#x03BB;" >
 <!ENTITY mu       "&#x03BC;" >
 <!ENTITY nu       "&#x03BD;" >
 <!ENTITY xi       "&#x03BE;" >
 <!ENTITY omicron  "&#x03BF;" >
 <!ENTITY pi       "&#x03C0;" >
 <!ENTITY rho      "&#x03C1;" >
 <!ENTITY sigmaf   "&#x03C2;" >
 <!ENTITY sigma    "&#x03C3;" >
 <!ENTITY tau      "&#x03C4;" >
 <!ENTITY upsilon  "&#x03C5;" >
 <!ENTITY phi      "&#x03C6;" >
 <!ENTITY chi      "&#x03C7;" >
 <!ENTITY psi      "&#x03C8;" >
 <!ENTITY omega    "&#x03C9;" >
 <!ENTITY thetasym "&#x03D1;" >
 <!ENTITY upsih    "&#x03D2;" >
 <!ENTITY piv      "&#x03D6;" >
 <!ENTITY ensp     "&#x2002;" >
 <!ENTITY emsp     "&#x2003;" >
 <!ENTITY thinsp   "&#x2009;" >
 <!ENTITY zwnj     "&#x200C;" >
 <!ENTITY zwj      "&#x200D;" >
 <!ENTITY lrm      "&#x200E;" >
 <!ENTITY rlm      "&#x200F;" >
 <!ENTITY ndash    "&#x2013;" >
 <!ENTITY mdash    "&#x2014;" >
 <!ENTITY lsquo    "&#x2018;" >
 <!ENTITY rsquo    "&#x2019;" >
 <!ENTITY sbquo    "&#x201A;" >
 <!ENTITY ldquo    "&#x201C;" >
 <!ENTITY rdquo    "&#x201D;" >
 <!ENTITY bdquo    "&#x201E;" >
 <!ENTITY dagger   "&#x2020;" >
 <!ENTITY Dagger   "&#x2021;" >
 <!ENTITY bull     "&#x2022;" >
 <!ENTITY hellip   "&#x2026;" >
 <!ENTITY permil   "&#x2030;" >
 <!ENTITY prime    "&#x2032;" >
 <!ENTITY Prime    "&#x2033;" >
 <!ENTITY lsaquo   "&#x2039;" >
 <!ENTITY rsaquo   "&#x203A;" >
 <!ENTITY oline    "&#x203E;" >
 <!ENTITY frasl    "&#x2044;" >
 <!ENTITY euro     "&#x20AC;" >
 <!ENTITY image    "&#x2111;" >
 <!ENTITY weierp   "&#x2118;" >
 <!ENTITY real     "&#x211C;" >
 <!ENTITY trade    "&#x2122;" >
 <!ENTITY alefsym  "&#x2135;" >
 <!ENTITY larr     "&#x2190;" >
 <!ENTITY uarr     "&#x2191;" >
 <!ENTITY rarr     "&#x2192;" >
 <!ENTITY darr     "&#x2193;" >
 <!ENTITY harr     "&#x2194;" >
 <!ENTITY crarr    "&#x21B5;" >
 <!ENTITY lArr     "&#x21D0;" >
 <!ENTITY uArr     "&#x21D1;" >
 <!ENTITY rArr     "&#x21D2;" >
 <!ENTITY dArr     "&#x21D3;" >
 <!ENTITY hArr     "&#x21D4;" >
 <!ENTITY forall   "&#x2200;" >
 <!ENTITY part     "&#x2202;" >
 <!ENTITY exist    "&#x2203;" >
 <!ENTITY empty    "&#x2205;" >
 <!ENTITY nabla    "&#x2207;" >
 <!ENTITY isin     "&#x2208;" >
 <!ENTITY notin    "&#x2209;" >
 <!ENTITY ni       "&#x220B;" >
 <!ENTITY prod     "&#x220F;" >
 <!ENTITY sum      "&#x2211;" >
 <!ENTITY minus    "&#x2212;" >
 <!ENTITY lowast   "&#x2217;" >
 <!ENTITY radic    "&#x221A;" >
 <!ENTITY prop     "&#x221D;" >
 <!ENTITY infin    "&#x221E;" >
 <!ENTITY ang      "&#x2220;" >
 <!ENTITY and      "&#x2227;" >
 <!ENTITY or       "&#x2228;" >
 <!ENTITY cap      "&#x2229;" >
 <!ENTITY cup      "&#x222A;" >
 <!ENTITY int      "&#x222B;" >
 <!ENTITY there4   "&#x2234;" >
 <!ENTITY sim      "&#x223C;" >
 <!ENTITY cong     "&#x2245;" >
 <!ENTITY asymp    "&#x2248;" >
 <!ENTITY ne       "&#x2260;" >
 <!ENTITY equiv    "&#x2261;" >
 <!ENTITY le       "&#x2264;" >
 <!ENTITY ge       "&#x2265;" >
 <!ENTITY sub      "&#x2282;" >
 <!ENTITY sup      "&#x2283;" >
 <!ENTITY nsub     "&#x2284;" >
 <!ENTITY sube     "&#x2286;" >
 <!ENTITY supe     "&#x2287;" >
 <!ENTITY oplus    "&#x2295;" >
 <!ENTITY otimes   "&#x2297;" >
 <!ENTITY perp     "&#x22A5;" >
 <!ENTITY sdot     "&#x22C5;" >
 <!ENTITY lceil    "&#x2308;" >
 <!ENTITY rceil    "&#x2309;" >
 <!ENTITY lfloor   "&#x230A;" >
 <!ENTITY rfloor   "&#x230B;" >
 <!ENTITY lang     "&#x2329;" >
 <!ENTITY rang     "&#x232A;" >
 <!ENTITY loz      "&#x25CA;" >
 <!ENTITY spades   "&#x2660;" >
 <!ENTITY clubs    "&#x2663;" >
 <!ENTITY hearts   "&#x2665;" >
 <!ENTITY diams    "&#x2666;" >
EOS

my $isolat1_entities = <<'EOS';
 <!ENTITY Agrave   "&#x000C0;" >
 <!ENTITY Aacute   "&#x000C1;" >
 <!ENTITY Acirc    "&#x000C2;" >
 <!ENTITY Atilde   "&#x000C3;" >
 <!ENTITY Auml     "&#x000C4;" >
 <!ENTITY Aring    "&#x000C5;" >
 <!ENTITY AElig    "&#x000C6;" >
 <!ENTITY Ccedil   "&#x000C7;" >
 <!ENTITY Egrave   "&#x000C8;" >
 <!ENTITY Eacute   "&#x000C9;" >
 <!ENTITY Ecirc    "&#x000CA;" >
 <!ENTITY Euml     "&#x000CB;" >
 <!ENTITY Igrave   "&#x000CC;" >
 <!ENTITY Iacute   "&#x000CD;" >
 <!ENTITY Icirc    "&#x000CE;" >
 <!ENTITY Iuml     "&#x000CF;" >
 <!ENTITY ETH      "&#x000D0;" >
 <!ENTITY Ntilde   "&#x000D1;" >
 <!ENTITY Ograve   "&#x000D2;" >
 <!ENTITY Oacute   "&#x000D3;" >
 <!ENTITY Ocirc    "&#x000D4;" >
 <!ENTITY Otilde   "&#x000D5;" >
 <!ENTITY Ouml     "&#x000D6;" >
 <!ENTITY Oslash   "&#x000D8;" >
 <!ENTITY Ugrave   "&#x000D9;" >
 <!ENTITY Uacute   "&#x000DA;" >
 <!ENTITY Ucirc    "&#x000DB;" >
 <!ENTITY Uuml     "&#x000DC;" >
 <!ENTITY Yacute   "&#x000DD;" >
 <!ENTITY THORN    "&#x000DE;" >
 <!ENTITY szlig    "&#x000DF;" >
 <!ENTITY agrave   "&#x000E0;" >
 <!ENTITY aacute   "&#x000E1;" >
 <!ENTITY acirc    "&#x000E2;" >
 <!ENTITY atilde   "&#x000E3;" >
 <!ENTITY auml     "&#x000E4;" >
 <!ENTITY aring    "&#x000E5;" >
 <!ENTITY aelig    "&#x000E6;" >
 <!ENTITY ccedil   "&#x000E7;" >
 <!ENTITY egrave   "&#x000E8;" >
 <!ENTITY eacute   "&#x000E9;" >
 <!ENTITY ecirc    "&#x000EA;" >
 <!ENTITY euml     "&#x000EB;" >
 <!ENTITY igrave   "&#x000EC;" >
 <!ENTITY iacute   "&#x000ED;" >
 <!ENTITY icirc    "&#x000EE;" >
 <!ENTITY iuml     "&#x000EF;" >
 <!ENTITY eth      "&#x000F0;" >
 <!ENTITY ntilde   "&#x000F1;" >
 <!ENTITY ograve   "&#x000F2;" >
 <!ENTITY oacute   "&#x000F3;" >
 <!ENTITY ocirc    "&#x000F4;" >
 <!ENTITY otilde   "&#x000F5;" >
 <!ENTITY ouml     "&#x000F6;" >
 <!ENTITY oslash   "&#x000F8;" >
 <!ENTITY ugrave   "&#x000F9;" >
 <!ENTITY uacute   "&#x000FA;" >
 <!ENTITY ucirc    "&#x000FB;" >
 <!ENTITY uuml     "&#x000FC;" >
 <!ENTITY yacute   "&#x000FD;" >
 <!ENTITY thorn    "&#x000FE;" >
 <!ENTITY yuml     "&#x000FF;" >
EOS

# Fetch the current contents of the scratch file as a scalar
sub getBufStr()
{
	local($/);
	binmode($outputFile, ':bytes') if isUnicodeSupported();
	$outputFile->seek(0, 0);
	return <$outputFile>;
}

# Set up the environment to run a test.
sub initEnv(@)
{
	my (%args) = @_;

	# Reset the scratch file
	$outputFile->seek(0, 0);
	$outputFile->truncate(0);
	binmode($outputFile, ':raw') if $] >= 5.006;

	# Overwrite OUTPUT so it goes to the scratch file
	$args{'OUTPUT'} = $outputFile unless(defined($args{'OUTPUT'}));

	# Set NAMESPACES, unless it's present
	$args{'NAMESPACES'} = 1 unless(defined($args{'NAMESPACES'}));

	undef($warning);
	defined($w = XML::Writer->new(%args)) || die "Cannot create XML writer";
}

#
# Check the results in the temporary output file.
#
# $expected - the exact output expected
#
sub checkResult($$)
{
	my ($expected, $explanation) = (@_);

	my $actual = getBufStr();

	if ($expected eq $actual) {
		ok(1, $explanation);
	} else {
		my @e = split(/\n/, $expected);
		my @a = split(/\n/, $actual);

		if (@e + @a == 2) {
			is(getBufStr(), $expected, $explanation);
		} else {
			if (eval {require Algorithm::Diff;}) {
				fail($explanation);

				Algorithm::Diff::traverse_sequences( \@e, \@a, {
					MATCH => sub { diag(" $e[$_[0]]\n"); },
					DISCARD_A => sub { diag("-$e[$_[0]]\n"); },
					DISCARD_B => sub { diag("+$a[$_[1]]\n"); }
				});
			} else {
				fail($explanation);
				diag("         got: '$actual'\n");
				diag("    expected: '$expected'\n");
			}
		}
	}

	wasNoWarning('(no warnings)');
}

#
# Expect an error of some sort, and check that the message matches.
#
# $pattern - a regular expression that must match the error message
# $value - the return value from an eval{} block
#
sub expectError($$) {
	my ($pattern, $value) = (@_);
	if (!ok((!defined($value) and ($@ =~ $pattern)), "Error expected: $pattern"))
	{
		diag('Actual error:');
		if ($@) {
			diag($@);
		} else {
			diag('(no error)');
			diag(getBufStr());
		}
	}
}

# Empty element tag with XML decl.
TEST: {
	initEnv();
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML declaration');
<?xml version="1.0"?>
<foo />
EOS
};

# Empty element tag, UTF-8.
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML declaration UTF-8');
<?xml version="1.0" encoding="UTF-8"?>
<foo />
EOS
};

# Empty element tag, ASCII.
TEST: {
	initEnv('ENCODING' => 'US-ASCII');
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML declaration ASCII');
<?xml version="1.0" encoding="US-ASCII"?>
<foo />
EOS
};

# Empty element tag, HTML entities.
# default encoding
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with HTML Entities');
<?xml version="1.0"?>
<foo />
EOS
};

# Empty element tag, HTML entities 2.
# default encoding
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities('^\t\r\n\x20-\x25\x27-\x3b\x3d\x3f-\x7e');
	initEnv('ENCODER' => $encoder);
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with HTML Entities, custom unsafe list');
<?xml version="1.0"?>
<foo />
EOS
};

# Empty element tag, XML entity data isolat1, encoding = default
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML Entities');
<?xml version="1.0"?>
<foo />
EOS
};

# Empty element tag, XML entity data isolat1, encoding = US-ASCII
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder, 'ENCODING' => 'US-ASCII');
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML Entities (US-ASCII)');
<?xml version="1.0" encoding="US-ASCII"?>
<foo />
EOS
};

# Empty element tag, XML entity data isolat1, encoding = US-ASCII
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder, 'ENCODING' => 'UTF-8');
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML Entities (UTF-8)');
<?xml version="1.0" encoding="UTF-8"?>
<foo />
EOS
};

# Empty element tag, XML entity data isolat1, encoding = UTF-8
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder, 'ENCODING' => 'UTF-8');
	$w->xmlDecl();
	$w->emptyTag("foo");
	$w->end();
	checkResult(<<"EOS", 'Empty element tag with XML Entities (UTF-8)');
<?xml version="1.0" encoding="UTF-8"?>
<foo />
EOS
};

# A document with a public and system identifier set, using startTag, HTML
# internal entities = yes, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, default encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, HTML
# internal entities = no, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 0);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, default encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, HTML
# internal entities = yes, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (no html entities, default encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, XML
# internal entities = yes, encoding = default
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder, 'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (xml entity data, default encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$isolat1_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, XML
# internal entities = no, encoding = default
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 0);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (xml entity data, default encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, XML
# internal entities = yes
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (xml entity data, default encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$isolat1_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag
# internal entities = yes, encoding = ''
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'ENCODING' => '', 'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, empty encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag
# internal entities = no, encoding = ''
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'ENCODING' => '',
			'WRITE_INTERNAL_ENTITIES' => 0);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, empty encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag
# internal entities = yes, encoding = ''
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'ENCODING' => '',
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, empty encoding)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, HTML
# internal entities = yes, encoding = UTF-8
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'ENCODING' => 'UTF-8',
			 'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, utf-8 encoding)');
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html></html>
EOS
};

# A document with a public and system identifier set, using startTag, HTML
# internal entities = yes, encoding = US-ASCII
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'ENCODING' => 'US-ASCII',
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->startTag('html');
	$w->endTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and system identifier (html entities, utf-8 encoding)');
<?xml version="1.0" encoding="US-ASCII"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html></html>
EOS
};

# A document with a public identifier and an empty system identifier
TEST: {
	initEnv();
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and an empty system identifier');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "">
<html />
EOS
};

# A document with a public identifier and an empty system identifier (html encoder)
# internal entities = yes, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder, WRITE_INTERNAL_ENTITIES => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and an empty system identifier (internal DTD)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "" [
$html_internal_entities]>
<html />
EOS
};

# A document with a public identifier and an empty system identifier (html encoder)
# internal entities = no, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 0);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and an empty system identifier (no internal DTD)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "">
<html />
EOS
};

# A document with a public identifier and an empty system identifier (html encoder)
# internal entities = yes, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', "-//W3C//DTD XHTML 1.1//EN",
						"");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with a public and an empty system identifier (no internal DTD)');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "" [
$html_internal_entities]>
<html />
EOS
};

# A document with only a system identifier set
TEST: {
	initEnv();
	$w->xmlDecl();
	$w->doctype('html', undef, "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with just a system identifier');
<?xml version="1.0"?>
<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html />
EOS
};

# A document with only a system identifier set (html entities)
# internal entities = yes, encoding = default
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder, WRITE_INTERNAL_ENTITIES => 1);
	$w->xmlDecl();
	$w->doctype('html', undef, "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with just a system identifier (html entities, internal DTD)');
<?xml version="1.0"?>
<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html />
EOS
};

# A document with only a system identifier set (html entities)
# internal entities = no, default encoding
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 0);
	$w->xmlDecl();
	$w->doctype('html', undef, "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with just a system identifier (html entities, no internal DTD)');
<?xml version="1.0"?>
<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html />
EOS
};

# A document with only a system identifier set (html entities)
# internal entities = yes, default encoding
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 1);
	$w->xmlDecl();
	$w->doctype('html', undef, "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->emptyTag('html');
	$w->end();
	checkResult(<<"EOS", 'A document with just a system identifier (html entities, internal DTD)');
<?xml version="1.0"?>
<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$html_internal_entities]>
<html />
EOS
};

# A document with only a system identifier set (html entities)
# internal entities = yes, default encoding
# indent = tabs
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder,
			'WRITE_INTERNAL_ENTITIES' => 1,
			'DATA_INDENT' => "\t");
	$w->xmlDecl();
	$w->doctype('html', undef, "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd");
	$w->emptyTag('html');
	$w->end();

	my $internal_entities = $html_internal_entities;
	$internal_entities =~ s/^\s+/\t/gm; # All leading spaces => single tab

	checkResult(<<"EOS", 'A document with just a system identifier (html entities, internal DTD tabs)');
<?xml version="1.0"?>
<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" [
$internal_entities]>
<html />
EOS
};

# Attributes 1
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->emptyTag("foo", "x" => "1>2");
	$w->end();
	checkResult("<foo x=\"1&gt;2\" />\n", 'Simple attributes UTF-8');
};

# Attributes 2
TEST: {
	initEnv('ENCODING' => 'US-ASCII');
	$w->emptyTag("foo", "x" => "1>2");
	$w->end();
	checkResult("<foo x=\"1&gt;2\" />\n", 'Simple attributes ASCII');
};

# Attributes 2 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "1>2");
	$w->end();
	checkResult("<foo x=\"1&gt;2\" />\n", 'Simple attributes HTML');
};

# Attributes 2 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "1>2");
	$w->end();
	checkResult("<foo x=\"1&#x3E;2\" />\n", 'Simple attributes XML isolat1');
};

# Attributes 2 - XML entities isonum
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "1>2");
	$w->end();
	checkResult("<foo x=\"1&gt;2\" />\n", 'Simple attributes XML isonum');
};

# Attributes 3
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->emptyTag("foo", "x" => "didn't");
	$w->end();
	checkResult("<foo x=\"didn't\" />\n", 'Attributes with apostrophe UTF-8');
};

# Attributes 4
TEST: {
	initEnv('ENCODING' => 'us-ascii');
	$w->emptyTag("foo", "x" => "didn't");
	$w->end();
	checkResult("<foo x=\"didn't\" />\n", 'Attributes with apostrophe ASCII');
};

# Attributes 4 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "didn't");
	$w->end();
	checkResult("<foo x=\"didn&#39;t\" />\n", 'Attributes with apostrophe HTML default');
};

# Attributes 4 - HTML entities, custom unsafe set
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities('^\t\r\n\x20-\x25\x27-\x3b\x3d\x3f-\x7e');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "didn't");
	$w->end();
	checkResult("<foo x=\"didn't\" />\n", 'Attributes with apostrophe HTML custom');
};

# Attributes 4c
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "didn't");
	$w->end();
	checkResult("<foo x=\"didn&#x27;t\" />\n", 'Attributes with apostrophe XML isolat1');
};

# Attributes 4d
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "didn't");
	$w->end();
	checkResult("<foo x=\"didn&apos;t\" />\n", 'Attributes with apostrophe XML isonum');
};

# Attributes 5
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->emptyTag("foo", "x" => "1\t2\r\n");
	$w->end();
	checkResult("<foo x=\"1&#9;2&#13;&#10;\" />\n", 'Attributes with control characters UTF-8');
};

# Attributes 6
TEST: {
	initEnv('ENCODING' => 'us-ascii');
	$w->emptyTag("foo", "x" => "1\t2\r\n");
	$w->end();
	checkResult("<foo x=\"1&#9;2&#13;&#10;\" />\n", 'Attributes with control characters ASCII');
};

# Attributes 6 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "1\t2\r\n");
	$w->end();
	checkResult("<foo x=\"1&#x09;2&#x0D;&#x0A;\" />\n", 'Attributes with control characters HTML');
};

# Attributes 6 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "1\t2\r\n");
	$w->end();
	checkResult("<foo x=\"1&#x09;2&#x0D;&#x0A;\" />\n", 'Attributes with control characters XML isolat1');
};

# Attributes 7
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->emptyTag("foo", "x" => "attribute \"quoted\" value");
	$w->end();
	checkResult("<foo x=\"attribute &quot;quoted&quot; value\" />\n", 'Attributes with double-quote characters UTF-8');
};

# Attributes 8
TEST: {
	initEnv('ENCODING' => 'us-ascii');
	$w->emptyTag("foo", "x" => "attribute \"quoted\" value");
	$w->end();
	checkResult("<foo x=\"attribute &quot;quoted&quot; value\" />\n", 'Attributes with double-quote characters ASCII');
};

# Attributes 8 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "attribute \"quoted\" value");
	$w->end();
	checkResult("<foo x=\"attribute &quot;quoted&quot; value\" />\n", 'Attributes with double-quote characters HTML');
};

# Attributes 8 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "attribute \"quoted\" value");
	$w->end();
	checkResult("<foo x=\"attribute &#x22;quoted&#x22; value\" />\n", 'Attributes with double-quote characters XML isolat1');
};

# Attributes 8 - XML entities isonum
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv('ENCODER' => $encoder);
	$w->emptyTag("foo", "x" => "attribute \"quoted\" value");
	$w->end();
	checkResult("<foo x=\"attribute &quot;quoted&quot; value\" />\n", 'Attributes with double-quote characters XML isonum');
};

# Character data 1
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->startTag("foo");
	$w->characters("Line with tabs\t\tand newlines\r\n");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with tabs\t\tand newlines\r\n</foo>\n", 'Unescaped control characters UTF-8');
};

# Character data 2
TEST: {
	initEnv('ENCODING' => 'US-ASCII');
	$w->startTag("foo");
	$w->characters("Line with tabs\t\tand newlines\r\n");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with tabs\t\tand newlines\r\n</foo>\n", 'Unescaped control characters US-ASCII');
};

# Character data 2 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("Line with tabs\t\tand newlines\r\n");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with tabs\t\tand newlines\r\n</foo>\n", 'Unescaped control characters HTML');
};

# Character data 2 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("Line with tabs\t\tand newlines\r\n");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with tabs\t\tand newlines\r\n</foo>\n", 'Unescaped control characters XML');
};

# Character data 3
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->startTag("foo");
	$w->characters("Line with \"quotes\" outside attribute");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with \"quotes\" outside attribute</foo>\n", 'Unescaped quotes in text UTF-8');
};

# Character data 4
TEST: {
	initEnv('ENCODING' => 'us-ascii');
	$w->startTag("foo");
	$w->characters("Line with \"quotes\" outside attribute");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with \"quotes\" outside attribute</foo>\n", 'Unescaped quotes in text ASCII');
};

# Character data 4 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("Line with \"quotes\" outside attribute");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with &quot;quotes&quot; outside attribute</foo>\n", 'Unescaped quotes in text HTML');
};

# Character data 4 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("Line with \"quotes\" outside attribute");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with &#x22;quotes&#x22; outside attribute</foo>\n", 'Unescaped quotes in text XML isolat1');
};

# Character data 4 - XML entities isonum
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("Line with \"quotes\" outside attribute");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>Line with &quot;quotes&quot; outside attribute</foo>\n", 'Unescaped quotes in text XML isonum');
};

# Character data 5
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->startTag("foo");
	$w->characters("");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo></foo>\n", 'empty text UTF-8');
};

# Character data 6
TEST: {
	initEnv('ENCODING' => 'us-ascii');
	$w->startTag("foo");
	$w->characters("");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo></foo>\n", 'empty text ASCII');
};

# Character data 6 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo></foo>\n", 'empty text HTML');
};

# Character data 6 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo></foo>\n", 'empty text XML');
};

# Character data 7
TEST: {
	initEnv('ENCODING' => 'UTF-8');
	$w->startTag("foo");
	$w->characters("didn't");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>didn't</foo>\n", 'Apostrophe text UTF-8');
};

# Character data 8
TEST: {
	initEnv('ENCODING' => 'us-ascii');
	$w->startTag("foo");
	$w->characters("didn't");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>didn't</foo>\n", 'Apostrophe text ASCII');
};

# Character data 8 - HTML entities
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("didn't");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>didn&#39;t</foo>\n", 'Apostrophe text HTML');
};

# Character data 8 - HTML entities, custom unsafe set
SKIP: {
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities('^\t\r\n\x20-\x25\x27-\x3b\x3d\x3f-\x7e');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("didn't");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>didn't</foo>\n", 'Apostrophe text HTML custom');
};

# Character data 8 - XML entities isolat1
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("didn't");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>didn&#x27;t</foo>\n", 'Apostrophe text XML isolat1');
};

# Character data 8 - XML entities isonum
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv('ENCODER' => $encoder);
	$w->startTag("foo");
	$w->characters("didn't");
	$w->endTag("foo");
	$w->end();
	checkResult("<foo>didn&apos;t</foo>\n", 'Apostrophe text XML isonum');
};

# Make sure UTF-8 is written properly
SKIP: {
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();

	initEnv(ENCODING => 'utf-8', DATA_MODE => 1);

	$w->xmlDecl();
	$w->comment("\$ \x{A3} \x{20AC}");
	$w->startTag('a');
	$w->dataElement('b', '$');

	# I need U+00A3 as an is_utf8 string; I want to keep the source ASCII.
	# There must be a better way to do this.
	require Encode;
	my $text = Encode::decode('iso-8859-1', "\x{A3}");
	$w->dataElement('b', $text);

	$w->dataElement('b', "\x{20AC}");
	$w->startTag('c');
	$w->cdata(" \$ \x{A3} \x{20AC} ");
	$w->endTag('c');
	$w->endTag('a');
	$w->end();

	checkResult(<<EOR, 'When requested, output should be UTF-8 encoded');
<?xml version="1.0" encoding="utf-8"?>
<!-- \$ \x{C2}\x{A3} \x{E2}\x{82}\x{AC} -->

<a>
<b>\x{24}</b>
<b>\x{C2}\x{A3}</b>
<b>\x{E2}\x{82}\x{AC}</b>
<c><![CDATA[ \$ \x{C2}\x{A3} \x{E2}\x{82}\x{AC} ]]></c>
</a>
EOR
};

# Make sure UTF-8 is written properly (ASCII encoded)
SKIP: {
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();

	initEnv(ENCODING => 'us-ascii', DATA_MODE => 1);

	$w->xmlDecl();
	$w->startTag('a');

	# I need U+00A3 as an is_utf8 string; I want to keep the source ASCII.
	# There must be a better way to do this.
	require Encode;
	my $text = Encode::decode('iso-8859-1', "\x{A3}");
	$w->dataElement('b', $text);

	$w->dataElement('b', "\x{20AC}");
	$w->endTag('a');
	$w->end();

	checkResult(<<EOR, 'When requested, output should be US-ASCII encoded');
<?xml version="1.0" encoding="us-ascii"?>

<a>
<b>&#xA3;</b>
<b>&#x20AC;</b>
</a>
EOR
};

# Make sure UTF-8 is written properly (HTML encoded, default encoding)
SKIP: {
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();
	skip $htmlSkipMessage, 2 unless isHTMLEntitiesAvailable();

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv('ENCODER' => $encoder, DATA_MODE => 1);

	$w->xmlDecl();
	$w->startTag('a');

	# I need U+00A3 as an is_utf8 string; I want to keep the source ASCII.
	# There must be a better way to do this.
	require Encode;
	my $text = Encode::decode('iso-8859-1', "\x{A3}");
	$w->dataElement('b', $text);

	$w->dataElement('b', "\x{20AC}");
	$w->endTag('a');
	$w->end();

	checkResult(<<EOR, 'When requested, output should be HTML encoded');
<?xml version="1.0"?>

<a>
<b>&pound;</b>
<b>&euro;</b>
</a>
EOR
};

# Make sure UTF-8 is written properly (XML encoded isolat1), default encoding
SKIP: {
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isolat1');
	initEnv('ENCODER' => $encoder, DATA_MODE => 1);

	$w->xmlDecl();
	$w->startTag('a');

	# I need U+00A3 as an is_utf8 string; I want to keep the source ASCII.
	# There must be a better way to do this.
	require Encode;
	my $text = Encode::decode('iso-8859-1', "\x{A3}");
	$w->dataElement('b', $text);

	$w->dataElement('b', "\x{20AC}");
	$w->endTag('a');
	$w->end();

	checkResult(<<EOR, 'When requested, output should be XML (isolat1) encoded');
<?xml version="1.0"?>

<a>
<b>&#xA3;</b>
<b>&#x20AC;</b>
</a>
EOR
};

# Make sure UTF-8 is written properly (XML encoded isonum), default encoding
SKIP: {
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv('ENCODER' => $encoder, DATA_MODE => 1);

	$w->xmlDecl();
	$w->startTag('a');

	# I need U+00A3 as an is_utf8 string; I want to keep the source ASCII.
	# There must be a better way to do this.
	require Encode;
	my $text = Encode::decode('iso-8859-1', "\x{A3}");
	$w->dataElement('b', $text);

	$w->dataElement('b', "\x{20AC}");
	$w->endTag('a');
	$w->end();

	checkResult(<<EOR, 'When requested, output should be XML (isonum) encoded');
<?xml version="1.0"?>

<a>
<b>&pound;</b>
<b>&#x20AC;</b>
</a>
EOR
};

# Test characters outside the BMP
SKIP: {
	skip $unicodeSkipMessage, 6 unless isUnicodeSupported();
	skip $htmlSkipMessage, 6 unless isHTMLEntitiesAvailable();

	my $s = "\x{10480}"; # U+10480 OSMANYA LETTER ALEF

	initEnv(ENCODING => 'utf-8');

	$w->dataElement('x', $s);
	$w->end();

	checkResult(<<"EOR", 'Characters outside the BMP should be encoded correctly in UTF-8');
<x>\xF0\x90\x92\x80</x>
EOR

	initEnv(ENCODING => 'us-ascii');

	$w->dataElement('x', $s);
	$w->end();

	checkResult(<<'EOR', 'Characters outside the BMP should be encoded correctly in US-ASCII');
<x>&#x10480;</x>
EOR

	my $encoder = XML::Writer::Encoding->html_entities();
	initEnv(ENCODER => $encoder);

	$w->dataElement('x', $s);
	$w->end();

	checkResult(<<'EOR', 'Characters outside the BMP should be encoded correctly in HTML encoding');
<x>&#x10480;</x>
EOR
}

# Test entity mapping combinations
SKIP: {
	skip $unicodeSkipMessage, 8 unless isUnicodeSupported();
	skip $xmlSkipMessage, 8 unless isXMLEntitiesDataAvailable();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	initEnv(ENCODING => 'utf-8', DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<"EOR", 'Characters should be encoded correctly in UTF-8');
<y>
<x>\xE2\x80\x98</x>
<x>\xE2\x80\x99</x>
</y>
EOR

	initEnv(ENCODING => 'us-ascii', DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Characters should be encoded correctly in US-ASCII');
<y>
<x>&#x2018;</x>
<x>&#x2019;</x>
</y>
EOR

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Characters should be encoded correctly in XML encoding (isonum)');
<y>
<x>&lsquo;</x>
<x>&rsquo;</x>
</y>
EOR

	$encoder = XML::Writer::Encoding->xml_entity_data('isopub');
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Characters should be encoded correctly in XML encoding (isopub)');
<y>
<x>&#x2018;</x>
<x>&rsquor;</x>
</y>
EOR
}

# Test entity mapping combinations
SKIP: {
	skip $unicodeSkipMessage, 4 unless isUnicodeSupported();
	skip $xmlSkipMessage, 4 unless isXMLEntitiesDataAvailable();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	require XML::Entities::Data;

	my $isonum = XML::Entities::Data::char2entity('isonum');
	my $isopub = XML::Entities::Data::char2entity('isopub');

	# Initial test with isonum taking precendence over isopub.

	my $combined = XML::Writer::Encoding::combine_data($isonum, $isopub);

	XML::Writer::Encoding::croak_unless_valid_entity_names($combined);

	my $encoder = XML::Writer::Encoding->custom_entity_data($combined);
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Combined characters should be encoded correctly in XML encoding (isonum first)');
<y>
<x>&lsquo;</x>
<x>&rsquo;</x>
</y>
EOR
	# Re-run test with isopub taking precendence over isonum.

	$combined = XML::Writer::Encoding::combine_data($isopub, $isonum);

	XML::Writer::Encoding::croak_unless_valid_entity_names($combined);

	$encoder = XML::Writer::Encoding->custom_entity_data($combined);
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Combined characters should be encoded correctly in XML encoding (isopub first)');
<y>
<x>&lsquo;</x>
<x>&rsquor;</x>
</y>
EOR
}

# Test entity mapping combinations 2
SKIP: {
	skip $unicodeSkipMessage, 4 unless isUnicodeSupported();
	skip $xmlSkipMessage, 4 unless isXMLEntitiesDataAvailable();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	my $combined = XML::Writer::Encoding::combine_xml_entities('isonum', 'isopub');

	XML::Writer::Encoding::croak_unless_valid_entity_names($combined);

	my $encoder = XML::Writer::Encoding->custom_entity_data($combined);
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Combined XML characters should be encoded correctly in XML encoding 2 (isonum first)');
<y>
<x>&lsquo;</x>
<x>&rsquo;</x>
</y>
EOR

	$combined = XML::Writer::Encoding::combine_xml_entities('isopub', 'isonum');

	XML::Writer::Encoding::croak_unless_valid_entity_names($combined);

	$encoder = XML::Writer::Encoding->custom_entity_data($combined);
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Combined XML characters should be encoded correctly in XML encoding 2 (isopub first)');
<y>
<x>&lsquo;</x>
<x>&rsquor;</x>
</y>
EOR
}

# Test entity mapping combinations 2
SKIP: {
	skip $unicodeSkipMessage, 4 unless isUnicodeSupported();
	skip $xmlSkipMessage, 4 unless isXMLEntitiesDataAvailable();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	my $encoder = XML::Writer::Encoding->xml_entity_data('isonum', 'isopub');
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Combined XML characters should be encoded correctly in XML encoding 3 (isonum first)');
<y>
<x>&lsquo;</x>
<x>&rsquo;</x>
</y>
EOR

	$encoder = XML::Writer::Encoding->xml_entity_data('isopub', 'isonum');
	initEnv(ENCODER => $encoder, DATA_MODE => 1);

	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Combined XML characters should be encoded correctly in XML encoding 3 (isopub first)');
<y>
<x>&lsquo;</x>
<x>&rsquor;</x>
</y>
EOR
}

# Test custom entity mapping, hand-generated
# Entity indent defaults to 1
SKIP: {
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	my %entities = (
		chr(38) => '&amp;',
		chr(0x00027) => '&apos;',
		chr(0x0003E) => '&gt;',
		chr(60) => '&lt;',
		chr(0x02018) => '&lsquo;',
		chr(0x02019) => '&rsquo;'
	);

	XML::Writer::Encoding::croak_unless_valid_entity_names(\%entities);

	my $encoder = XML::Writer::Encoding->custom_entity_data(\%entities);
	initEnv(ENCODER => $encoder, WRITE_INTERNAL_ENTITIES => 1, DATA_MODE => 1);

	$w->doctype('y');
	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Custom XML characters should be encoded correctly in XML encoding');
<!DOCTYPE y [
 <!ENTITY amp      "&#x00026;" >
 <!ENTITY apos     "&#x00027;" >
 <!ENTITY lt       "&#x0003C;" >
 <!ENTITY gt       "&#x0003E;" >
 <!ENTITY lsquo    "&#x02018;" >
 <!ENTITY rsquo    "&#x02019;" >
]>

<y>
<x>&lsquo;</x>
<x>&rsquo;</x>
</y>
EOR

}

# Test custom entity mapping, hand-generated
# Entity indent follows DATA_INDENT level (2)
SKIP: {
	skip $unicodeSkipMessage, 2 unless isUnicodeSupported();
	skip $xmlSkipMessage, 2 unless isXMLEntitiesDataAvailable();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	my %entities = (
		chr(38) => '&amp;',
		chr(0x00027) => '&apos;',
		chr(0x0003E) => '&gt;',
		chr(60) => '&lt;',
		chr(0x02018) => '&lsquo;',
		chr(0x02019) => '&rsquo;'
	);

	XML::Writer::Encoding::croak_unless_valid_entity_names(\%entities);

	my $encoder = XML::Writer::Encoding->custom_entity_data(\%entities);
	initEnv(ENCODER => $encoder, DATA_MODE => 1, WRITE_INTERNAL_ENTITIES => 1,
			DATA_INDENT => 2);

	$w->doctype('y');
	$w->startTag('y');
	$w->dataElement('x', $ls);
	$w->dataElement('x', $rs);
	$w->endTag();
	$w->end();

	checkResult(<<'EOR', 'Custom XML characters should be indented 2 levels in XML encoding');
<!DOCTYPE y [
  <!ENTITY amp      "&#x00026;" >
  <!ENTITY apos     "&#x00027;" >
  <!ENTITY lt       "&#x0003C;" >
  <!ENTITY gt       "&#x0003E;" >
  <!ENTITY lsquo    "&#x02018;" >
  <!ENTITY rsquo    "&#x02019;" >
]>

<y>
  <x>&lsquo;</x>
  <x>&rsquo;</x>
</y>
EOR

}

# Test custom invalid entity mappings, hand generated
SKIP: {
	skip $unicodeSkipMessage, 1 unless isUnicodeSupported();

	my $ls = "\x{2018}"; # U+02018 lsquo
	my $rs = "\x{2019}"; # U+02019 rsquo or rsquor

	my %entities = (
		chr(38) => '&amp;',
		chr(0x00027) => '&apos;',
		chr(0x0003E) => '&gt;',
		chr(60) => '&lt;',
		chr(0x02018) => '&lsquo;',
		chr(0x02019) => '&rsquo'
	);

	expectError("Entity name \".*\" must start with & and end with ;", eval {
		XML::Writer::Encoding::croak_unless_valid_entity_names(\%entities);
	});

}

# Free test resources
$outputFile->close() or die "Unable to close temporary file: $!";

1;

__END__
