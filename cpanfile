recommends 'perl', '5.008_001';
suggests 'HTML::Entities', '2.00';
suggests 'XML::Entities::Data';

on develop => sub {
    recommends 'version';
    recommends 'IO::File';
    recommends 'FindBin';
    recommends 'File::Spec';
    recommends 'HTML::Entities';
};

on build => sub {
    requires 'perl', '5.006_000';
};

on test => sub {
    requires 'Test::More', '0.047';
    recommends 'HTML::Entities', '2.00';
    recommends 'XML::Entities::Data';
    recommends 'Test::Pod';
    recommends 'Test::Pod::Coverage';
};
