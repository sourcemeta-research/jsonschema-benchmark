# JSON Schema Benchmark

The goal of this benchmark is measure the performance of various JSON Schema validators.
Each validator is run with multiple schemas and a collection of those documents expected to be valid for that schema.
While implementations that do not produce the correct result on validation will be flagged, our goal is not to test for correctness.
For correctness tests of validators, please see [Bowtie](https://bowtie.report/).

## Setup

The benchmark requires Python, make, and Docker.
[uv](https://github.com/astral-sh/uv) is used for dependency management in the Python scripts.
To run all the benchmarks, a report can be produced via `make dist/report.csv`.
To plot the runtime for each implementation, run `make plots`.

## Implementations

Each implementation is run via Docker.
First, a Docker container is built with all the necessary dependencies.
Then, at runtime, a folder containing the schema and the necessary dependencies is mounted and the time to validate all documents is measured.

- [ajv](https://ajv.js.org/)
- [@exodus/schemasafe](https://github.com/ExodusMovement/schemasafe)
- [boon](https://github.com/santhosh-tekuri/boon)
- [go-jsonschema](https://github.com/omissis/go-jsonschema)
- [Corvus.JsonSchema](https://github.com/corvus-dotnet/Corvus.JsonSchema)
- [hyperjump](https://github.com/hyperjump-io/json-schema)
- [json_schemer](https://github.com/davishmcclurg/json_schemer)
- [jsonschema](https://python-jsonschema.readthedocs.io/en/stable/)
- [jsontoolkit](https://github.com/sourcemeta/jsontoolkit)

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
