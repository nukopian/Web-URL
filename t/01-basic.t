use v5.38;
use Test2::V0;

use Web::URL;

subtest 'Web::URL::string' => sub {
    my @tests = (
        [__LINE__, []                                   => ''],
        [__LINE__, [{}]                                 => ''],
        [__LINE__, [{a => 1}]                           => '?a=1'],
        [__LINE__, [{a => 1, b => 2}]                   => '?a=1&b=2'],
        [__LINE__, [{a => 1, b => 2, c => [1, 2, 3]}]   => '?a=1&b=2&c=1&c=2&c=3'],
        [__LINE__, ['']                                 => '/'],
        [__LINE__, ['/']                                => '/'],
        [__LINE__, ['', {a => 1}]                       => '/?a=1'],
        [__LINE__, ['/', {a => 1, b => 2}]              => '/?a=1&b=2'],
        [__LINE__, ['foo']                              => '/foo'],
        [__LINE__, ['/foo']                             => '/foo'],
        [__LINE__, ['/foo', '']                         => '/foo/'],
        [__LINE__, ['/foo', '/']                        => '/foo/'],
        [__LINE__, ['foo', 'bar']                       => '/foo/bar'],
        [__LINE__, ['foo', 'bar', {a => 1}]             => '/foo/bar?a=1'],
        [__LINE__, ['foo', ':a', {a => 1}]              => '/foo/1'],
        [__LINE__, ['foo', ':b', {}]                    => '/foo/null'],
        [__LINE__, ['foo', ':b']                        => '/foo/null'],
        [__LINE__, ['foo', ':b', {a => 1}]              => '/foo/null?a=1'],
        [__LINE__, ['foo', ':a', {a => 1, b => 2}]      => '/foo/1?b=2'],
        [__LINE__, ['foo', ':a', {a => [1, 2], b => 2}] => '/foo/1?a=2&b=2'],
        [__LINE__, ['foo', '*a', {a => 1}]              => '/foo/1'],
        [__LINE__, ['foo', '*b', {}]                    => '/foo/'],
        [__LINE__, ['foo', '*b']                        => '/foo/'],
        [__LINE__, ['foo', '*b', {a => 1}]              => '/foo/?a=1'],
        [__LINE__, ['foo', '*a', {a => 1, b => 2}]      => '/foo/1?b=2'],
        [__LINE__, ['foo', 'bar', '']                   => '/foo/bar/'],
        [__LINE__, ['foo', 'bar', '#baz']               => '/foo/bar#baz'],
        [__LINE__, ['foo', 'bar', '?baz=10']            => '/foo/bar?baz=10'],
        [__LINE__, ['foo', 'bar?baz=10']                => '/foo/bar?baz=10'],
        [__LINE__, ['foo', 'bar?baz=10', {baz => 20}]   => '/foo/bar?baz=20'],
    );

    for my $t (@tests) {
        my($ln, $args, $exp) = @$t;
        is Web::URL::string(@$args), $exp, "Web::URL::string #$ln";
    }
};

subtest 'Web::URL::from' => sub {
    # construct from a string
    my $u = Web::URL::from('https://foo.com?a=1&b=2');

    isa_ok $u, 'Web::URL';
    is $u->as_string => 'https://foo.com?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;

    # test deterministic ordering of query-string parameters
    $u = Web::URL::from('https://foo.com?b=2&a=1');

    is $u->as_string => 'https://foo.com?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;

    # construct from Web::URL object
    my $c = Web::URL::from($u);

    is $c->as_string => $u->as_string,
        'ok - Web::URL::as_string, #' . __LINE__;

    $c = Web::URL::from($u, 'bar');

    is $c->as_string => 'https://foo.com/bar?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;
};

subtest 'Web::URL::new' => sub {
    my $u = Web::URL->new('https://foo.com?a=1&b=2');

    isa_ok $u, 'Web::URL';

    is $u->as_string => 'https://foo.com?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;

    # test deterministic ordering of query-string parameters
    $u = Web::URL->new('https://foo.com?b=2&a=1');

    is $u->as_string => 'https://foo.com?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;
};

subtest 'url::from_URI' => sub {
    my $u;

    $u = Web::URL::from_URI('https://foo.com/bar?a=1&b=2');

    isa_ok $u, 'Web::URL';
    is $u->as_string => 'https://foo.com/bar?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;

    # again, test deterministic ordering of query-string parameters
    $u = Web::URL::from_URI('https://foo.com/bar?b=2&a=1');

    is $u->as_string => 'https://foo.com/bar?a=1&b=2',
        'ok - Web::URL::as_string, #' . __LINE__;

    $u = Web::URL::from_URI('https://foo.com/bar#fragment?b=2&a=1', {b => 4});

    is $u->as_string => 'https://foo.com/bar#fragment?a=1&b=4',
        'ok - Web::URL::as_string, #' . __LINE__;

    is $u->as_URI->as_string => 'https://foo.com/bar#fragment?a=1&b=4',
        'ok - Web::URL::as_URI, #' . __LINE__;
};

done_testing;
