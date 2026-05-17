use v5.38;
use Test2::V0;

ok eval { require Web::URL; 1 }, 'Web::URL loads';

subtest 'VERSION check' => sub {
SKIP:
    {
        skip 'Skipping VERSION test under Dist::Zilla', 1
            unless $ENV{DZIL_TESTING};

        ok defined $Web::URL::VERSION, 'VERSION is defined';
    }
};

no warnings 'once';
isa_ok $Web::URL::ENCODER, 'URI::Encode';

done_testing;
