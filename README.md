# NAME

Web::URL - Immutable, composable URL value type with placeholder and query semantics

# SYNOPSIS

    use Web::URL;

    my $u = Web::URL->new(
        'https://example.com',
        'users',
        ':id',
        { id => 42, tags => ['a','b'] },
    );

    say $u;                 # https://example.com/users/42?tags=a&tags=b
    say $u->as_str;         # same
    say $u->as_URI->host;   # example.com

    # Composition using Web::URL objects
    my $base = Web::URL->new('https://api.example.com', 'v1');
    my $full = Web::URL->new($base, 'users', ':id', { id => 10 });

    say $full;              # https://api.example.com/v1/users/10

    # From a URI object or string
    my $v = Web::URL::from_URI('https://foo.com/a/b?x=1&x=2&y=3');
    say $v;                 # https://foo.com/a/b?x=1&x=2&y=3

# DESCRIPTION

`Web::URL` provides a small, explicit, and immutable value type for
constructing and normalising URLs. It offers a compositional interface
for building URLs from path fragments, placeholders, hashrefs, query
parameters, `Mojo::Parameters` objects, and other `Web::URL` instances.

The module is intentionally minimal: no mutation, no guessing, and no
builder objects. A URL is treated as a value, not a mutable structure.

# CONSTRUCTORS

## from

    my $u = Web::URL::from(@parts);

Primary constructor. Accepts a list of parts, which may include:

- strings (path segments, absolute URLs, fragments, query strings)
- hashrefs (query parameters; scalar or arrayref values)
- objects providing `pairs` (e.g. `Mojo::Parameters`)
- other `Web::URL` objects (their path and query are merged)

Examples:

    Web::URL::from('foo','bar');              # /foo/bar
    Web::URL::from('foo',{a=>1});             # /foo?a=1
    Web::URL::from('foo',{a=>[1,2]});         # /foo?a=1&a=2
    Web::URL::from($other_url,'extra');       # composition

## from\_URI

    my $u = Web::URL::from_URI($uri);

Constructs a `Web::URL` from a `URI` object or string. Query parameters,
path, and fragments are preserved. The resulting URL is fed through the
same composition pipeline as ["from"](#from).

## new

    my $u = Web::URL->new(@parts);

Idiomatic Perl constructor. This is a thin alias for ["from"](#from) and
accepts the same arguments. It exists for compatibility with common
Perl OO expectations.

# PLACEHOLDERS

Path segments beginning with `:` or `*` are treated as placeholders.

## :name

Replaced with the encoded value of `name`, or `null` if missing.

If the value is an arrayref, only the first element is consumed; the
remaining elements stay in the query string.

## \*name

Replaced with the encoded value of `name`, or removed entirely if
missing.

Arrayrefs behave the same as for `:name`.

Examples:

    Web::URL::from('foo',':id',{id=>10});         # /foo/10
    Web::URL::from('foo',':id',{});               # /foo/null
    Web::URL::from('foo','*id',{});               # /foo/
    Web::URL::from('foo',':id',{id=>[10,20]});    # /foo/10?id=20

# QUERY PARAMETERS

Query parameters may come from:

- hashrefs (scalars or arrayrefs)
- `Mojo::Parameters` objects
- query strings embedded in path fragments
- other `Web::URL` objects

Repeated keys are preserved and emitted in sorted order:

    { tag => ['b','a'], x => 1 }

becomes:

    ?tag=a&tag=b&x=1

User-provided parameters override those extracted from the URL.

# IMMUTABILITY

`Web::URL` objects are immutable value types. Internally they are blessed
read-only scalar references. Methods never mutate the object.

# METHODS

## as\_str

    my $str = $u->as_str;

Returns the URL as a string.

## as\_URI

    my $uri = $u->as_URI;

Returns a `URI` object representing the URL.

# STRINGIFICATION

`Web::URL` objects stringify to their URL via overload.

# DESIGN

`Web::URL` uses a three-phase pipeline:

1. Consolidate parts into a base URL and parameter hash
2. Merge path placeholders, consuming parameter values
3. Rebuild the query string deterministically

# LIMITATIONS

- This module does not attempt full RFC 3986 normalisation.
- Array-valued parameters are supported, but ordering is normalised
(sorted) for deterministic output.
- Placeholder syntax is limited to `:name` and `*name`.

# SEE ALSO

[URI](https://metacpan.org/pod/URI), [Mojo::Parameters](https://metacpan.org/pod/Mojo%3A%3AParameters)

# AUTHOR

Iain Campbell <cpanic@cpan.org>

# LICENSE

MIT.
