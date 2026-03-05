# JSON Schema Utils compiler with JMC C backend

The JSU compiler uses JSON Model as an intermediate language to
generate efficient validation code from a schema.

See [bowtie report](https://bowtie.report/#/implementations/python-jsu) for
the current functionality coverage.

## Schema to Model Conversion

Although the automatic translation is not perfect, it supports **most** of JSON Schema
features, attempts to fix common schema issues (eg typical cases of misplaced keywords
are fixed to reflect the designer intention, which may lead to invalid data reported
from this benchmark point of view), and string formats can be actually checked in many
cases (eg dates or URLs), although this is disabled with `--no-format`.

## Backend Model Compilation

The backend compiler generates source code in the target language to validate
JSON values, which is further converted to an executable if appropriate.
It uses `re2` as its default regular expression engine, and _loose_ numbers
(i.e. 1.0 is an integer, 2 is a float).

## Benchmarking Run

Benchmarking time is an average over 20-1000 (repeat depends on the expected
slowness of the runs) validations of all tests values after loading them into
memory.

Exit status is 0 if _all_ JSON values were validated, 1 otherwise.

## Validation Status

Although not all values are considered valid, from the implementer point of view
the rejected values are rightfully rejected as they do not correspond to expected
JSON values for the target application, even if they strictly conform to the schema.

- ansible-meta: 3 issues
  - 105: `dependecies` prop typo because of fixed `additionalProperties`
  - 201/312: `argument_specs` prop because of fixed `additionalProperties`
- cypress: 1 issue
  - 8: the `reporter` string does not point to a js file.
- yamllint: 18 issues, _but_ 98% of the schema is ignored…
  - the 18 differences are raw random strings containing:
    - 10 C# source code
    - 6 files or directories path
    - 2 XML data

More cases would fail if formats are enabled.
