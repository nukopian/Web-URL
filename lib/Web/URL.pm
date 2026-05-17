package Web::URL;    # ABSTRACT: Immutable, composable URL value type

use v5.38;

use Ref::Util    qw(is_arrayref is_blessed_ref is_hashref);
use Scalar::Util qw(readonly);
use URI          qw();
use URI::Encode  qw();

use namespace::clean;
use overload (
    '""'     => sub { shift->as_str() },
    fallback => 1,
);

our $ENCODER = URI::Encode->new();
our $DECODE  = sub { $ENCODER->decode(@_) };
our $ENCODE  = sub { $ENCODER->encode(@_) };


sub _consolidate (@ps) {
    # consolidate url parts into a single string;
    # consolidate query-string key-values into params collection;
    # remove the query-string from the url.
    my $u = '';
    my $q = '';
    my %kv;

    for my $p (@ps) {
        if (ref $p) {
            if (is_blessed_ref($p)) {
                if ($p->isa(__PACKAGE__)) {
                    ($p = $p->as_str()) =~ s/\?(.*)$//;

                    $q .= $q ? "&$1" : $1;
                    $u .= $p;
                }
                elsif ($p->can('pairs')) {
                    my @pairs = $p->pairs();

                    while (my($k, $v) = splice @pairs, 0, 2) {
                        push @{ $kv{$k} }, $v;
                    }
                }
                else {
                    next;
                }
            }
            elsif (is_hashref($p)) {
                while (my($k, $v) = each %$p) {
                    push @{ $kv{$k} }, is_arrayref($v) ? @$v : $v;
                }
            }
            else {
                next;
            }
        }
        else {
            if (!$u && $p =~ m/^\w+:|\/{2}/) {
                $u = $p;
            }
            else {
                $p =~ s/^\/+//;
                $u =~ s/\/+$//;

                $u .= $p =~ m/^[#?]/ ? $p : "/$p";
            }
        }
    }

    $u .= "?$q" if $q;

    if ($u =~ s/\?(.*)$//) {
        for my $p (split /&/, $1, -1) {
            my($k, $v) = split /=/, $p, 2;

            push @{ $kv{$k} //= [] }, $DECODE->($v) unless exists $kv{$k};
        }
    }

    return $u, \%kv;
}


sub _merge_path_vals ($u, $kv = {}) {
    # merge path parameter values, deleting any merged items
    my @ps = split m/\//, $u, -1;

    for my $p (@ps) {
        if ($p =~ m/^([:*])([A-Za-z0-9_-]+)$/) {
            my($t, $k) = ($1, $2);

            if (exists $kv->{$k}) {
                my $v;

                if (is_arrayref($kv->{$k})) {
                    $v = shift @{ $kv->{$k} };
                    delete $kv->{$k} unless @{ $kv->{$k} };
                }
                else {
                    $v = delete $kv->{$k};
                }

                $v = $ENCODE->($v // '');
                $p = length $v ? $v : ($t eq ':' ? 'null' : '');
            }
            else {
                $p = $t eq ':' ? 'null' : '';
            }
        }
    }

    return join('/', @ps), $kv;
}


sub _merge_qs_vals ($u, $kv = {}) {
    # reconstitute query-string from parameters and append it to the URL
    return $u unless %$kv;

    my $q = '';

    for my $k (sort keys %$kv) {
        my $v = is_arrayref($kv->{$k}) ? $kv->{$k} : [$kv->{$k}];

        for my $v (sort @$v) {
            $q .= length $q ? '&' : '?';
            $q .= $k . '=' . $ENCODE->($v // '');
        }
    }

    return $u . $q;
}


sub str (@ps) { _merge_qs_vals(_merge_path_vals(_consolidate(@ps))) }


sub as_str ($self) { $$self }


sub as_URI ($self) { URI->new($$self) }


sub from (@ps) {
    readonly(my $u = str(@ps));
    bless \$u;
}


sub from_URI ($u) {
    $u = URI->new($u) unless is_blessed_ref($u) && $u->isa('URI');

    my $b  = $u->scheme . '://' . $u->authority;
    my $p  = $u->path // '';
    my $f  = $u->fragment;
    my @fs = defined $f ? "#$f" : ();
    my %kv = $u->query_form;

    $p =~ s/^\///;

    return from($b, $p, @fs, \%kv);
}


sub new ($class, @ps) { from(@ps) }

1;
__END__
=head1 NAME

Web::URL - Immutable, composable URL value type with placeholder and query semantics

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Web::URL> provides a small, explicit, and immutable value type for
constructing and normalising URLs. It offers a compositional interface
for building URLs from path fragments, placeholders, hashrefs, query
parameters, C<Mojo::Parameters> objects, and other C<Web::URL> instances.

The module is intentionally minimal: no mutation, no guessing, and no
builder objects. A URL is treated as a value, not a mutable structure.

=head1 CONSTRUCTORS

=head2 from

    my $u = Web::URL::from(@parts);

Primary constructor. Accepts a list of parts, which may include:

=over 4

=item *

strings (path segments, absolute URLs, fragments, query strings)

=item *

hashrefs (query parameters; scalar or arrayref values)

=item *

objects providing C<pairs> (e.g. C<Mojo::Parameters>)

=item *

other C<Web::URL> objects (their path and query are merged)

=back

Examples:

    Web::URL::from('foo','bar');              # /foo/bar
    Web::URL::from('foo',{a=>1});             # /foo?a=1
    Web::URL::from('foo',{a=>[1,2]});         # /foo?a=1&a=2
    Web::URL::from($other_url,'extra');       # composition

=head2 from_URI

    my $u = Web::URL::from_URI($uri);

Constructs a C<Web::URL> from a C<URI> object or string. Query parameters,
path, and fragments are preserved. The resulting URL is fed through the
same composition pipeline as L</from>.

=head2 new

    my $u = Web::URL->new(@parts);

Idiomatic Perl constructor. This is a thin alias for L</from> and
accepts the same arguments. It exists for compatibility with common
Perl OO expectations.

=head1 PLACEHOLDERS

Path segments beginning with C<:> or C<*> are treated as placeholders.

=head2 :name

Replaced with the encoded value of C<name>, or C<null> if missing.

If the value is an arrayref, only the first element is consumed; the
remaining elements stay in the query string.

=head2 *name

Replaced with the encoded value of C<name>, or removed entirely if
missing.

Arrayrefs behave the same as for C<:name>.

Examples:

    Web::URL::from('foo',':id',{id=>10});         # /foo/10
    Web::URL::from('foo',':id',{});               # /foo/null
    Web::URL::from('foo','*id',{});               # /foo/
    Web::URL::from('foo',':id',{id=>[10,20]});    # /foo/10?id=20

=head1 QUERY PARAMETERS

Query parameters may come from:

=over 4

=item *

hashrefs (scalars or arrayrefs)

=item *

C<Mojo::Parameters> objects

=item *

query strings embedded in path fragments

=item *

other C<Web::URL> objects

=back

Repeated keys are preserved and emitted in sorted order:

    { tag => ['b','a'], x => 1 }

becomes:

    ?tag=a&tag=b&x=1

User-provided parameters override those extracted from the URL.

=head1 IMMUTABILITY

C<Web::URL> objects are immutable value types. Internally they are blessed
read-only scalar references. Methods never mutate the object.

=head1 METHODS

=head2 as_str

    my $str = $u->as_str;

Returns the URL as a string.

=head2 as_URI

    my $uri = $u->as_URI;

Returns a C<URI> object representing the URL.

=head1 STRINGIFICATION

C<Web::URL> objects stringify to their URL via overload.

=head1 DESIGN

C<Web::URL> uses a three-phase pipeline:

=over 4

=item 1.

Consolidate parts into a base URL and parameter hash

=item 2.

Merge path placeholders, consuming parameter values

=item 3.

Rebuild the query string deterministically

=back

=head1 LIMITATIONS

=over 4

=item *

This module does not attempt full RFC 3986 normalisation.

=item *

Array-valued parameters are supported, but ordering is normalised
(sorted) for deterministic output.

=item *

Placeholder syntax is limited to C<:name> and C<*name>.

=back

=head1 SEE ALSO

L<URI>, L<Mojo::Parameters>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

MIT.

=cut
