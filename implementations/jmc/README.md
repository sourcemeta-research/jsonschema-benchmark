# Benchmark runs with JSON Model Compiler

JMC is **not** a JSON Schema implementation per se, but implements code generation
for JSON Model which aims at validating JSON data structures.
This benchmark uses json-schema-utils proof-of-concept JSON schema to JSON model
converter to generate models.

## Schema to Model Conversion

The JSON Schema Utils conversion occurs in three phases:

1. the schema is first simplified, especially wrt reference management
2. if it has a corresponding _official_ model, use it (based on `$id`)
3. otherwise, generate a model in _loose_ mode (which accept any bug-looking oddity)

The automatic translation is not strictly faithfull to schema semantics due to corner case
differences, attempts to fix schema issues (eg typical cases of misplaced keywords
are fixed to reflect the designer intention, which may lead to invalid data reported
from this benchmark point of view), that it is designed to convert draft-2020-12 schemas,
whereas this benchmark mostly contains older draft-07 schemas (2018), and that
string formats are actually checked in some cases (eg dates or URLs).

## Model Compilation

Compilation builds an executable from generated C code mostly with `re2` as a regular
expression engine, with loose numbers.

The compilation time reported includes converting the schema to a model,
generating C source code from the model, and compiling the C code and the (small)
support library to an executable.

For scripting language (Python, JS, Perl), the compilation time reported is the
time to generate the script from the schema via the model.

## Benchmarking

Benchmarking time is an average over 20-1000 (repeat depends on the expected
slowness of the runs) validations of all tests values after loading them into memory.

Exit status is 0 if _all_ JSON values were validated, 1 otherwise.

## Validation Status

Although not all values are considered valid, from the implementation point of view
the rejected values are rightfully rejected as they do not correspond to expected
JSON values, even if they strictly conform to the schema without format.

- ansible-meta: 3 issues
  - 105: `dependecies` prop typo because of fixed `additionalProperties`
  - 201/312: `argument_specs` prop because of fixed `additionalProperties`
- cspell:
  - 2 regular expressions uselessly re extensions incompatible with re2 and java re.
- cypress: several URLs in the instances are _not_ urls thus are rightfully rejected.
- helm-chart-lock: quite a few issues related to corner case string value checks.
- openapi: many issues…
  - 26: `"<local-terminal-IP-address>"` is not really a valid URI reference
  - a lot of cases are rejected because the API parameter _schema_ checks are
    performed and probably too strict.
  - NOTE: beware that thus bench does validate string formats
  - NOTE: the openapi schema is *not* the official one, but a stripped down version
    which does not validate route input and output schemas.
- krakend: the model uses strange internal url-looking nested definitions.
- yamllint: 18 issues, 98% of the schema is ignored…
  - the 18 differences are raw strings, model conversion rightfully infer object requirement
    thus reject strings like "hello world" as valid yamllint values.
