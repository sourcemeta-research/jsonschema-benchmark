# Benchmark runs with JSON Model Compiler

JMC is **not** a JSON Schema implementation per se, but implements code generation
for JSON Model which aims at validating JSON data structures.
This benchmark uses json-schema-utils proof-of-concept JSON schema to JSON model
converter to generate models.

## Schema to Model Conversion

The conversion occurs in three phases:

1. the schema is first simplified, especially wrt reference management
2. then if it has a corresponding _official_ model, use it (based on `$id`)
3. otherwise, generate a model in _loose_ mode (which accept any bug-looking oddity)

The automatic translation is not strictly faithfull to schema semantics due to corner case
differences, attempts to fix schema issues (eg typical cases of misplaced keywords
are fixed to reflect the designer intention, which may lead to invalid data reported
from this benchmark point of view) and that it is designed to convert draft-2020-12 schemas,
whereas this benchmark mostly contains older draft-07 schemas.

## Model Compilation

Compilation builds an executable from generated C code mostly with `re2` as a regular
expression engine, with loose numbers.

The compilation time reported includes converting the schema to a model,
generating C source code from the model, and compiling the C code and the (small)
support library to an executable.

## Benchmarking

Benchmarking time is an average over 100 validations of all tests values after
loading them into memory.

Exit status is 0 if all JSON values were validated, 1 otherwise.

## Status

- [x] ansible-meta pass=330 fail=3 error=0
  - 105: `dependecies` prop typo because of fixed `additionalProperties`
  - 201/312: `argument_specs` prop because of fixed `additionalProperties`
- [x] aws-cdk pass=483 fail=0 error=0
- [x] babelrc pass=794 fail=0 error=0
- [x] clang-format pass=133 fail=0 error=0
- [x] cmake-presets pass=967 fail=0 error=0
- [x] code-climate pass=2484 fail=0 error=0
- [x] cql2 pass=109 fail=0 error=0
- [x] cspell **pcre2** pass=981 fail=0 error=0
  - 2 regular expressions uselessly re extensions incompatible with re2
- [x] cypress pass=981 fail=0 error=0
- [x] deno pass=987 fail=0 error=0
- [x] dependabot pass=967 fail=0 error=0
- [x] draft-04 pass=563 fail=0 error=0
- [x] fabric-mod pass=911 fail=0 error=0
- [x] geojson pass=500 fail=0 error=0
- [x] gitpod-configuration pass=986 fail=0 error=0
- [x] helm-chart-lock pass=3888 fail=0 error=0
- [x] importmap pass=964 fail=0 error=0
- [x] jasmine pass=980 fail=0 error=0
- [x] jsconfig pass=981 fail=0 error=0
- [x] jshintrc pass=966 fail=0 error=0
- [x] krakend pass=47 fail=0 error=0
- [x] lazygit pass=279 fail=1 error=0
  - 47-c: obscure issue with utf8 string length, `bmstowcs` returns _-1_
- [x] lerna pass=985 fail=0 error=0
- [x] nest-cli pass=1025 fail=0 error=0
- [x] omnisharp pass=987 fail=0 error=0
- [x] openapi pass=106 fail=1 error=0
  - 26: `"<local-terminal-IP-address>"` is not really a valid URI reference
  - NOTE: beware that the provided schema does _not_ validate schemas…
- [x] pre-commit-hooks pass=985 fail=0 error=0
- [x] pulumi pass=3807 fail=0 error=0
- [x] semantic-release pass=794 fail=0 error=0
- [x] stale pass=961 fail=0 error=0
- [x] stylecop pass=983 fail=0 error=0
- [x] tmuxinator pass=382 fail=0 error=0
- [x] ui5 pass=942 fail=0 error=0
- [x] ui5-manifest **pcre2** pass=611 fail=0 error=0
  - one regular expressions extension incompatible with re2
- [x] unreal-engine-uproject pass=859 fail=0 error=0
- [x] vercel pass=710 fail=0 error=0
- [x] yamllint pass=966 fail=18 error=0
  - the 18 differences are raw strings, model conversion rightfully infer object requirement
    thus reject strings like "hello world" as valid yamllint values

## Make Commands

```sh
make BENCH=lerna run  # run for one benchmark directory
make runs.txt         # run for all benchmark directories, with results in runs.txt
make clean            # local and docker cleanup
make version          # show jmc versions
```

## TODO

- add python benchmarking
- add js benchmarking

## Docker Commands

```sh
docker build -t jmc -f Dockerfile .
docker run -it --entrypoint /bin/bash jmc
docker run -v ../../schemas:/schemas jmc ...
```
