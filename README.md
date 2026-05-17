# Web::URL

Web::URL is a small, explicit, immutable URL value type for Perl.

It provides a compositional interface for building URLs from path
fragments, placeholders, hashrefs, query parameters, Mojo::Parameters
objects, and other Web::URL instances.

## Features

- Immutable value type
- Placeholder support (`:id`, `*id`)
- Array-valued query parameters
- Deterministic output ordering
- Composition of URL objects
- `from_URI` constructor
- Idiomatic `new` constructor

## Installation

```shell
perl Makefile.PL
make
make test
make install
```

## Documentation

Full documentation is available in the module itself:

```shell
perldoc Web::URL
```

## Repository

https://github.com/nukopian/Web-URL

## License

MIT.
