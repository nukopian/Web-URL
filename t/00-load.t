use v5.38;
use Test2::V0;

ok eval { require Web::URL; 1 }, 'load Web::URL';

subtest 'VERSION check' => sub {
SKIP:
    {
        unless ($ENV{DZIL_TESTING}) {
            skip 'skip VERSION check if not using Dist::Zilla', 1;
        }

        ok defined $Web::URL::VERSION, 'VERSION is defined';
    }
};

no warnings 'once';

# This test just proves the module loaded correctly
isa_ok $Web::URL::ENCODER, 'URI::Encode';

done_testing;
