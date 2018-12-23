#############################################################################
# Encoding.pm - write an XML string with parameterised character references.
# Copyright (c) 2018 Nicholas Cull <run2000@.com>
# Redistribution and use in source and compiled forms, with or without
# modification, are permitted under any circumstances.  No warranty.
#############################################################################

package XML::Writer::Encoding;

require 5.004;

use strict;
use vars qw($VERSION);
use Carp;

$VERSION = "0.699";

# Public factory methods

# Takes a name of an entity set from XML::Entities::Data
sub xml_entity_data {
	my ($class, $entitySet) = @_;
	require XML::Entities::Data;

	return &custom_entity_data($class, XML::Entities::Data::char2entity($entitySet));
}

# Takes a map reference of ordinals to entity names
sub custom_entity_data {
	my ($class) = shift;
	my %char2entity = %{$_[0]};
	my $self;

	sub num_entity {
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
		$$ref =~ s/([^\n\r\t !\#\$%\(-;=?-~])/$char2entity{$1} || num_entity($1)/ge;
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
		$$ref =~ s/([^ !\#\$%\(-;=?-~])/$char2entity{$1} || num_entity($1)/ge;
		$$ref;
	};

	my $make_entity_refs = sub {
		my $output = $_[0];

		foreach my $charVal (sort (keys (%char2entity))) {
			my $entityName = $char2entity{$charVal};

			$entityName =~ s/^&//;
			$entityName =~ s/;$//;

			$output->print (sprintf (' <!ENTITY %-8s "', $entityName));

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
		'WANTS_REFS' => 1,
		'DEFAULT_ENCODING' => 'US-ASCII'
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
	my $encoding;

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

		# Don't know if we're ASCII-clean, so assume UTF-8
		$encoding = 'UTF-8';

	} else {
		$encode_entities = \&HTML::Entities::encode_entities;

		$encode_attributes = sub {
			my $value = HTML::Entities::encode_entities($_[0]);

			# Any additional safety for CR, LF, TAB
			$value =~ s/\x0a/\&#x0A\;/g;
			$value =~ s/\x0d/\&#x0D\;/g;
			$value =~ s/\x09/\&#x09\;/g;

			return $value;
		};

		# Default encoding is 7-bit ASCII clean
		$encoding = 'US-ASCII';
	}

	my $make_entity_refs = sub {
		my $output = $_[0];

		foreach my $charVal (sort (keys (%HTML::Entities::char2entity))) {
			my $entityName = $HTML::Entities::char2entity{$charVal};

			$entityName =~ s/^&//;
			$entityName =~ s/;$//;

			next if ($entityName =~ m/^#/);

			$output->print (sprintf (' <!ENTITY %-8s "', $entityName));

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
		'WANTS_REFS' => 1,
		'DEFAULT_ENCODING' => $encoding
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
		'WANTS_REFS' => 0,
		'DEFAULT_ENCODING' => 'US-ASCII'
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
		'WANTS_REFS' => 0,
		'DEFAULT_ENCODING' => 'UTF-8'
	};

	bless $self, $class;
	return $self;
}

# Public methods.
#

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

sub default_encoding {
	my $self = shift;
	return $self->{DEFAULT_ENCODING};
}

# Static method for combining sets of entities.
#

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
	my %char2ent = ();

	require XML::Entities::Data;

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
		foreach my $el (keys (%$set)) {
			my $entName = $set->{$el};
			Carp::croak ("Entity name \"$entName\" must start with & and end with ;")
				unless ($entName =~ m/^&.*;$/);
		}
	}
}

1;
