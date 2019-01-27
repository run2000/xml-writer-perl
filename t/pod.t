use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

plan tests => 2;

pod_file_ok('lib/XML/Writer.pm');
pod_file_ok('lib/XML/Writer/Encoding.pm');
