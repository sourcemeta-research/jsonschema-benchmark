# JSON Schema Utils compiler with JMC C JMC Backend

The JSU compiler uses JSON Model as an intermediate language to
generate efficient validation code from a schema.

See [bowtie report](https://bowtie.report/#/implementations/python-jsu) for
the current functionality coverage.

## Schema to Model Conversion

The automatic conversion supports **all** of JSON Schema v3 to v7 features,
and a significant and growing subset of JSON Schema 2019-09 and 2020-12.
Distinctive features such as fixing common schema issues (eg typical cases of
misplaced keywords) are _disactivated_.
Also, although some schemas have _native_ models which are expected to be
functionally equivalent or stricter, they _not_ used.

## Backend Model Compilation

The backend compiler generates source code in the target language to validate
JSON values, which is further converted to an executable if appropriate.
It uses `re2` as its default regular expression engine, and _loose_ numbers
(i.e. 1.0 is an integer, 2 is a float).

## Benchmarking Run

Benchmarking measures are performed in 3 phases:

- a cold run over all values
- a warmup loop of up to 1000 iterations bounded at 10 seconds over all values
- a hot run over all values

Exit status is 0 if _all_ JSON values were validated, 1 otherwise.
