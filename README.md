# JSON Schema Benchmark

The goal of this benchmark is measure the performance of various JSON Schema validators.
Each validator is run with multiple schemas and a collection of those documents expected to be valid for that schema.
While implementations that do not produce the correct result on validation will be flagged, our goal is not to test for correctness.
For correctness tests of validators, please see [Bowtie](https://bowtie.report/).

## Setup

The benchmark requires Python, make, and Docker.
[uv](https://github.com/astral-sh/uv) is used for dependency management in the Python scripts.
To run all the benchmarks, a report can be produced via `make dist/report.csv`.
The `Makefile` accepts parameters `IMPLEMENTATIONS` to specify which implementations to run and `RUNS` for the number of runs per implementation.
For example, `make IMPLEMENTATIONS='blaze jsoncons' RUNS=5` will run the Blaze and jsoncons implementations 5 times each.
To plot the runtime for each implementation, run `make plots`.

## Implementations

Each implementation is run via Docker.
First, a Docker container is built with all the necessary dependencies.
Then, at runtime, a folder containing the schema and the necessary dependencies is mounted and the time to validate all documents is measured.
All implementations can be found in the `implementations/` subdirectory.
A summary of these implementations is given below.

- [Ajv](https://ajv.js.org/) (JS)
- [Blaze](https://github.com/sourcemeta/blaze) (C++)
- [@exodus/schemasafe](https://github.com/ExodusMovement/schemasafe) (JS)
- [boon](https://github.com/santhosh-tekuri/boon) (Rust)
- [Corvus.JsonSchema](https://github.com/corvus-dotnet/Corvus.JsonSchema) (C#)
- [Hyperjump](https://github.com/hyperjump-io/json-schema) (JS)
- [Opis](https://opis.io/json-schema) (PHP)
- [jsoncons](https://github.com/danielaparker/jsoncons) (C++)
- [json_schemer](https://github.com/davishmcclurg/json_schemer) (Ruby)
- [json-schema-validator](https://github.com/networknt/json-schema-validator) (Java)
- [json-schema-validator](https://github.com/OptimumCode/json-schema-validator) (Kotlin)
- [jsonschema](https://github.com/santhosh-tekuri/jsonschema/) (Go)
- [jsonschema](https://python-jsonschema.readthedocs.io/en/stable/) (Python)
- [JsonSchema.NET](https://github.com/json-everything/json-everything) (C#)
- [JSV](https://github.com/lud/jsv) (Elixir)

Note that some implementations are currently ignored by default to limit the runtime of the benchmark.
These implementations are identified by a `.benchmark-ignore` file in the implementation subdirectory.
To run one of these implementations, it must be explicitly specified as described above.

## Adding a new implementation

First, each implementation must have a `Dockerfile` that copies in any necessary scripts and installs dependencies.
There is also a `version.sh` script that must output the version of the implementation (often extracted from whatever dependency management tool is used).
Finally, appropriate targets must be added to the `Makefile` to build the Docker container and run the benchmark.
We will gladly accept pull requests to add new implementations.

## Results

The most recent results can be seen (via GitHub Actions)[https://github.com/sourcemeta-research/jsonschema-benchmark/actions/workflows/ci.yml].
Note that while there is noise in the results across runs due to the use of shared infrastructure, the relative ranking of different implementations is generally consistent.
It also worth noting that some implementations compile schemas ahead of time into a more efficient representation, while others interpret the entire schema at runtime.
Currently we operate under the assumption that a schema changes infrequently enough that the compilation process is unlikely to be a performance bottleneck.
As such, we currently only measure the time for validation and exclude any compilation time.
