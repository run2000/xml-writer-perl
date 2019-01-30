recommends 'perl', '5.008_001';
suggests 'HTML::Entities', '2.00';
suggests 'XML::Entities::Data';

on develop => sub {
    requires 'Devel::Cover';
    requires 'Template::Toolkit';
    requires 'Test::Pod::Coverage';
    requires 'PPI::HTML';
    requires 'HTML::Parser';
    requires 'Minilla';
};

on configure => sub {
    requires 'Module::Build';
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
