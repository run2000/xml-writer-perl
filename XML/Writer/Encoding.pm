#############################################################################
# Encoding.pm - write an XML string with parameterised character references.
# Copyright (c) 2018 Nicholas Cull <run2000@the mailers of g.com>
# Redistribution and use in source and compiled forms, with or without
# modification, are permitted under any circumstances.  No warranty.
#############################################################################

package XML::Writer::Encoding;

require 5.004;
require Exporter;
@ISA = qw(Exporter);

use strict;
use vars qw($VERSION @EXPORT_OK);
use Carp;

$VERSION = "0.699";
@EXPORT_OK = qw(combine_data combine_xml_entities croak_unless_valid_entity_names);

########################################################################
# Public factory methods
########################################################################

# Takes a name of an entity set from XML::Entities::Data
sub xml_entity_data {
	my ($class) = shift;

	return custom_entity_data($class, combine_xml_entities(@_));
}

# Takes a map reference of ordinals to entity names
sub custom_entity_data {
	my ($class) = shift;
	my %char2entity = %{(int (@_) == 1) ? $_[0] : combine_data(@_)};
	my $self;

	sub _num_entity {
		sprintf('&#x%02X;', ord($_[0]));
	}

	my $encode_entities = sub {
		return undef unless defined $_[0];

		my $ref;
		if (defined wantarray) {
			my $x = $_[0];
			$ref = \$x;     # copy
		} else {
			$ref = \$_[0];  # modify in-place
		}

		# Encode control chars, high bit chars and '<', '&', '>', ''' and '"'
		$$ref =~ s/([^\n\r\t !\#\$%\(-;=?-~])/$char2entity{$1} || _num_entity($1)/ge;
		$$ref;
	};

	my $encode_attributes = sub {
		return undef unless defined $_[0];
		my $ref;
		if (defined wantarray) {
			my $x = $_[0];
			$ref = \$x;     # copy
		} else {
			$ref = \$_[0];  # modify in-place
		}

		# Encode control chars, high bit chars and '<', '&', '>', ''' and '"'
		$$ref =~ s/([^ !\#\$%\(-;=?-~])/$char2entity{$1} || _num_entity($1)/ge;
		$$ref;
	};

	my $make_entity_refs = sub {
		my $output = $_[0];
		my $indent = $_[1] || ' ';

		foreach my $charVal (sort (keys (%char2entity))) {
			my $entityName = $char2entity{$charVal};

			$entityName =~ s/^&//;
			$entityName =~ s/;$//;

			$output->print (sprintf ('%s<!ENTITY %-8s "', $indent, $entityName));

			for my $c (split //, $charVal) {
				$output->print (sprintf ('&#x%05X;', ord($c)));
			}
			$output->print ("\" >\n");
		}
	};

	$self = {
		'ENCODE' => $encode_entities,
		'ATTRIBUTE' => $encode_attributes,
		'MAKE_REFS' => $make_entity_refs,
		'WANTS_REFS' => 1
	};

	bless $self, $class;
	return $self;
}

# Constructs from the HTML::Entities set
sub html_entities {
	my ($class, $unsafe_chars) = @_;
	my $self;

	require HTML::Entities;

	my $encode_entities;
	my $encode_attributes;

	if (defined ($unsafe_chars) && ($unsafe_chars ne '')) {
		$encode_entities = sub {
			HTML::Entities::encode_entities($_[0], $unsafe_chars);
		};

		$encode_attributes = sub {
			my $value = HTML::Entities::encode_entities($_[0], $unsafe_chars);

			# Any additional safety for CR, LF, TAB
			$value =~ s/\x0a/\&#x0A\;/g;
			$value =~ s/\x0d/\&#x0D\;/g;
			$value =~ s/\x09/\&#x09\;/g;

			return $value;
		};

	} else {
		$encode_entities = sub {
			HTML::Entities::encode_entities($_[0]);
		};

		$encode_attributes = sub {
			my $value = HTML::Entities::encode_entities($_[0]);

			# Any additional safety for CR, LF, TAB
			$value =~ s/\x0a/\&#x0A\;/g;
			$value =~ s/\x0d/\&#x0D\;/g;
			$value =~ s/\x09/\&#x09\;/g;

			return $value;
		};
	}

	my $make_entity_refs = sub {
		my $output = $_[0];
		my $indent = $_[1] || ' ';

		foreach my $charVal (sort (keys (%HTML::Entities::char2entity))) {
			my $entityName = $HTML::Entities::char2entity{$charVal};

			$entityName =~ s/^&//;
			$entityName =~ s/;$//;

			next if ($entityName =~ m/^#/);

			$output->print (sprintf ('%s<!ENTITY %-8s "', $indent, $entityName));

			for my $c (split //, $charVal) {
				$output->print (sprintf ('&#x%04X;', ord($c)));
			}
			$output->print ("\" >\n");
		}
	};

	$self = {
		'ENCODE' => $encode_entities,
		'ATTRIBUTE' => $encode_attributes,
		'MAKE_REFS' => $make_entity_refs,
		'WANTS_REFS' => 1
	};

	bless $self, $class;
	return $self;
}

# Uses numeric entities for non-ASCII data
sub numeric_entities {
	my ($class) = @_;
	my $self;

	my $encode_entities = sub {
		my $data = shift;

		if ($data =~ tr/&<>//) {
			$data =~ s/\&/\&amp\;/g;
			$data =~ s/\</\&lt\;/g;
			$data =~ s/\>/\&gt\;/g;
		}

		$data =~ s/([^\x00-\x7F])/sprintf('&#x%X;', ord($1))/ge;

		return $data;
	};

	my $encode_attribute = sub {
		my $value = shift;

		if ($value =~ tr/&<>"//) { #"
			$value =~ s/\&/\&amp\;/g;
			$value =~ s/\</\&lt\;/g;
			$value =~ s/\>/\&gt\;/g;
			$value =~ s/\"/\&quot\;/g;
		}

		$value =~ s/\x0a/\&#10\;/g;
		$value =~ s/\x0d/\&#13\;/g;
		$value =~ s/\x09/\&#9\;/g;

		$value =~ s/([^\x00-\x7F])/sprintf('&#x%X;', ord($1))/ge;

		return $value;
	};

	my $make_entity_refs = sub {};

	$self = {
		'ENCODE' => $encode_entities,
		'ATTRIBUTE' => $encode_attribute,
		'MAKE_REFS' => $make_entity_refs,
		'WANTS_REFS' => 0
	};

	bless $self, $class;
	return $self;
}

# Uses the minimal XML entity set. Everything else as-is.
sub minimal_entities {
	my ($class) = @_;
	my $self;

	my $encode_entities = sub {
		my $data = shift;

		if ($data =~ tr/&<>//) {
			$data =~ s/\&/\&amp\;/g;
			$data =~ s/\</\&lt\;/g;
			$data =~ s/\>/\&gt\;/g;
		}

		return $data;
	};

	my $encode_attribute = sub {
		my $value = shift;

		if ($value =~ tr/&<>"//) { #"
			$value =~ s/\&/\&amp\;/g;
			$value =~ s/\</\&lt\;/g;
			$value =~ s/\>/\&gt\;/g;
			$value =~ s/\"/\&quot\;/g;
		}

		$value =~ s/\x0a/\&#10\;/g;
		$value =~ s/\x0d/\&#13\;/g;
		$value =~ s/\x09/\&#9\;/g;

		return $value;
	};

	my $make_entity_refs = sub {};

	$self = {
		'ENCODE' => $encode_entities,
		'ATTRIBUTE' => $encode_attribute,
		'MAKE_REFS' => $make_entity_refs,
		'WANTS_REFS' => 0
	};

	bless $self, $class;
	return $self;
}

########################################################################
# Public methods.
########################################################################

sub encode {
	my $self = shift;
	return &{$self->{ENCODE}};
}

sub attribute {
	my $self = shift;
	return &{$self->{ATTRIBUTE}};
}

sub make_refs {
	my $self = shift;
	return &{$self->{MAKE_REFS}};
}

sub wants_refs {
	my $self = shift;
	return $self->{WANTS_REFS};
}

########################################################################
# Static methods for combining sets of entities.
########################################################################

# Combine references of hashes, first character reference wins.
sub combine_data {

	my %char2ent = ();

	foreach my $set (@_) {
		foreach my $el (keys (%$set)) {
			$char2ent{$el} = $set->{$el}
				unless (exists $char2ent{$el});
		}
	}
	return \%char2ent;
}

# Combine character sets by name, first character reference wins.
sub combine_xml_entities {
	require XML::Entities::Data;

	my %char2ent = ();

	foreach my $setname (@_) {
		my $set = XML::Entities::Data::char2entity($setname);

		foreach my $el (keys (%$set)) {
			$char2ent{$el} = $set->{$el}
				unless (exists $char2ent{$el});
		}
	}
	return \%char2ent;
}

# For each given hash reference, ensure the hash names conform
# to the required format.
sub croak_unless_valid_entity_names {

	foreach my $set (@_) {
		foreach my $entName (values (%$set)) {
			Carp::croak ("Entity name \"$entName\" must start with & and end with ;")
				unless ($entName =~ m/^&\w[\w\.\-]*;$/);
		}
	}
}

1;
__END__

########################################################################
# POD Documentation
########################################################################

=head1 NAME

XML::Writer::Encoding - Perl extension for encoding XML entities.

=head1 SYNOPSIS

  use XML::Writer;
  use XML::Writer::Encoding;
  use IO::File;

  my $output = IO::File->new(">output.xml");
  my $encoder = XML::Writer::Encoding->html_entities();

  my $writer = XML::Writer->new(OUTPUT => $output,
                                ENCODER => $encoder);
  $writer->startTag("greeting",
                    "class" => "simple");
  $writer->characters("This program writes \"Hello, world!\"");
  $writer->endTag("greeting");
  $writer->end();
  $output->close();


=head1 DESCRIPTION

C<XML::Writer::Encoding> is a helper module for the C<XML::Writer> module.
The module handles encoding of characters as numeric entities, or
as defined character entities. The definition of the character
entities can came from the C<HTML::Entities> module, the
C<XML::Entities::Data> module, or an arbitrary mapping supplied by a
hash reference.


=head1 AUTHOR

Nicholas Cull E<lt>run2000@the mailers of g.comE<gt>


=head1 METHODS

=head2 Factory Methods

=over 4

=item numeric_entities()

Create an C<XML::Writer::Encoding> object that encodes text as numeric
entity data:

  my $encoder = XML::Writer::Encoding->numeric_entities();
  my $writer = XML::Writer->new(ENCODER => $encoder);

There are no arguments for this factory method.

The resulting encoding is equivalent to calling
C<< XML::Writer->new(ENCODING => 'us-ascii') >>.

=item minimal_entities()

Create an C<XML::Writer::Encoding> object that encodes text using only
the minimum pre-defined XML entity references:

  my $encoder = XML::Writer::Encoding->minimal_entities();
  my $writer = XML::Writer->new(ENCODER => $encoder);

For text data, the special characters C<E<lt>>, C<E<gt>>, and C<&>
are encoded with named entities.

For attribute value data, the special characters C<E<lt>>, C<E<gt>>,
C<&>, and C<"> are encoded as named entities. Additionally, the
carriage return (\r), linefeed (\n), and tab (\t) characters are
encoded as numeric entities.

All other text is retained as UTF-8 encoded text.

There are no arguments for this factory method.

The resulting encoding is equivalent to calling
C<< XML::Writer->new() >>.

=item html_entities([$unsafe_chars])

Create an C<XML::Writer::Encoding> object that encodes text using the
entity set contained by the C<HTML::Entities> module:

  my $encoder = XML::Writer::Encoding->html_entities();
  my $writer = XML::Writer->new(ENCODER => $encoder);

The optional C<unsafe_chars> argument can be given to specify which
characters to consider unsafe.  The unsafe characters is specified
using the regular expression character class syntax (what you find
within square brackets in regular expressions).

When C<unsafe_chars> is not provided, the resulting encoding is
7-bit ASCII safe. Otherwise, 7-bit ASCII safety depends on the set of
unsafe characters specified.

See the C<HTML::Entities::encode_entities()> method for details.

=item xml_entity_data($entity_set_name[, $entity_set_name2[, ...])

Create an C<XML::Writer::Encoding> object that encodes text using one
or more of the entity sets provided by the C<XML::Entities::Data>
module.

  my $encoder = XML::Writer::Encoding->xml_entity_data('isonum');
  my $writer = XML::Writer->new(ENCODER => $encoder);

The entity_set_name argument specifies which entity set or sets
should be used.

Specify multiple entity set names to combine entity sets from the
C<XML::Entities::Data> module. Where more than one entity name maps
onto a given character, the first encountered name takes precedence.

The resulting encoding is 7-bit ASCII safe.

=over 4

=item Note:

There can be multiple mappings from a code point to an entity name.
Using the 'all' set can result in an unpredictable mapping.

=back

=item custom_entity_data(\%entity_set)

Create an C<XML::Writer::Encoding> object that encodes text using the
supplied character to entity name mapping.

  my %customEntNames = (
    chr(0x0022) => '&quot;',
    chr(0x0026) => '&amp;',
    chr(0x0027) => '&apos;',
    chr(0x003E) => '&gt;',
    chr(0x003C) => '&lt;'
  );
  my $encoder = XML::Writer::Encoding->custom_entity_data(
                                                  \%customEntNames);
  my $writer = XML::Writer->new(ENCODER => $encoder);

The entity_set parameter may be supplied by the C<combine_data()> or
C<combine_xml_entities()> methods.

The resulting encoding is 7-bit ASCII safe.

=back

=head2 Instance Methods

These are called internally by C<XML::Writer>. The following method
descriptions are informational.

=over 4

=item encode($text)

Encode the given document text using the XML encoding determined by
the factory method.

=item attribute($text)

Encode the given attribute value text using the XML encoding determined
by the factory method.

=item make_refs($writer[, $indent])

Encode the named entities in an internal DTD section.

=item wants_refs()

Determine whether the factory can supply named entity references
when C<make_refs($writer)> is called.

=back

=head2 Static Methods

=over 4

=item combine_data(\%set1[, \%set2 [, ...]])

Combine multiple sets of character to entity name mappings into
a new hash reference, in argument order. Where more than one entity
name maps onto a given character, the first encountered name takes
precedence.

=item combine_xml_entities($set_name1[, $set_name2[, ...]])

Combine multiple sets of character to entity name mappings from the
C<XML::Entities::Data> module into a new hash reference, in argument
order. Where more than one entity name maps onto a given character,
the first encountered name takes precedence.

=item croak_unless_valid_entity_names(\%entity_set)

Ensure that all given entity names in the given hash reference
conform to the expected format. Entity names must start with an
C<&>, end with a C<;>, and contain word characters, hyphens, or
periods.

=back

=head1 DTD DECLARATION

When C<XML::Writer::doctype()> is called, the encoder can construct
an internal DTD for the named entity mappings. This feature is
available for the C<html_entities()>, C<xml_entity_data()>, and
C<custom_entity_data()> encoders.

This behaviour can be enabled at construction time by setting the
C<WRITE_INTERNAL_ENTITIES> to 1, as follows:

  my $xmlEncoding = XML::Writer::Encoding->html_entities();
  my $writer = new XML::Writer(ENCODER => $xmlEncoding,
                               WRITE_INTERNAL_ENTITIES => 1);

  $writer->doctype('html', '-//W3C//DTD XHTML 1.0 Strict//EN',
                   'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd');

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Nicholas Cull E<lt>run2000@the mailers of g.comE<gt>

Redistribution and use in source and compiled forms, with or without
modification, are permitted under any circumstances.  No warranty.


=head1 SEE ALSO

=over 4

=item XML::Writer

=item HTML::Entities

=item XML::Entities::Data

=back

=cut
