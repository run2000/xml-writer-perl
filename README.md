[![Build Status](https://travis-ci.org/run2000/xml-writer-perl.svg?branch=master)](https://travis-ci.org/run2000/xml-writer-perl)
# NAME

XML::Writer - Perl extension for writing XML documents.

# SYNOPSIS

[XML::Writer](https://metacpan.org/pod/XML::Writer) is a simple Perl module for writing XML documents: it
takes care of constructing markup and escaping data correctly, and by
default, it also performs a significant amount of well-formedness
checking on the output, to make certain (for example) that start and
end tags match, that there is exactly one document element, and that
there are not duplicate attribute names.

# EXAMPLE

    my $writer = new XML::Writer();

    $writer->startTag('greeting', 'type' => 'simple');
    $writer->characters("Hello, world!");
    $writer->endTag('greeting');
    $writer->end();

# NOTES

This fork is interested in using character entity encoding from
[HTML::Entities](https://metacpan.org/pod/HTML::Entities), [XML::Entities::Data](https://metacpan.org/pod/XML::Entities::Data), or a custom entity set,
for encoding non-ASCII characters. See `XML::Writer::Encoding`
for details.

If necessary, error-checking can be turned off for production use.

See the Changes file for detailed changes between versions.

# COPYRIGHT

Copyright (c) 1999 by Megginson Technologies.

Copyright (c) 2003 Ed Avis <ed@membled.com>

Copyright (c) 2004-2010 Joseph Walton <joe@kafsemo.org>

# CONTACT

Current development is hosted at [http://josephw.github.com/xml-writer-perl/](http://josephw.github.com/xml-writer-perl/).
