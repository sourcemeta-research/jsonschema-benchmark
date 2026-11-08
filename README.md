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
- [ata-validator](https://github.com/ata-core/ata-validator) (JS)
- [Blaze](https://github.com/sourcemeta/blaze) (C++)
- [@exodus/schemasafe](https://github.com/ExodusMovement/schemasafe) (JS)
- [boon](https://github.com/santhosh-tekuri/boon) (Rust)
- [Corvus.JsonSchema](https://github.com/corvus-dotnet/Corvus.JsonSchema) (C#, TypeScript, Rust, Python, C++, Ruby, PHP, Swift, Java, Go, Object Pascal, R, Julia)
- [Hyperjump](https://github.com/hyperjump-io/json-schema) (JS)
- [JSU](https://github.com/zx80/json-schema-utils) (C, Java, JS, Python, Perl)
- [Opis](https://opis.io/json-schema) (PHP)
- [jsoncons](https://github.com/danielaparker/jsoncons) (C++)
- [json_schemer](https://github.com/davishmcclurg/json_schemer) (Ruby)
- [json-schema-validator](https://github.com/networknt/json-schema-validator) (Java)
- [json-schema-validator](https://github.com/OptimumCode/json-schema-validator) (Kotlin)
- [jsonschema](https://github.com/santhosh-tekuri/jsonschema/) (Go)
- [jsonschema](https://python-jsonschema.readthedocs.io/en/stable/) (Python)
- [jsonschema-rs](https://github.com/Stranger6667/jsonschema/tree/master/crates/jsonschema-py) (Python, backed by the jsonschema Rust crate)
- [JsonSchema.NET](https://github.com/json-everything/json-everything) (C#)
- [JSV](https://github.com/lud/jsv) (Elixir)

Note that some implementations are currently ignored by default to limit the runtime of the benchmark.
These implementations are identified by a `.benchmark-ignore` file in the implementation subdirectory.
To run one of these implementations, it must be explicitly specified as described above.

## Acceptance criteria

As the name implies, this benchmark is for JSON Schema implementations.
Every implementation included in this benchmark must aim to be a fully compliant implementation of the [JSON Schema](https://json-schema.org/) standard, including all required features as defined by the specification.
Bugs, spec misunderstandings, and incomplete support for optional features are perfectly acceptable.
However, implementations that intentionally do not support required parts of the specification, or that only implement a subset of the language with no intention of reaching full compliance, do not qualify for inclusion.
A strong signal of eligibility is being listed in [Bowtie](https://bowtie.report/) and in the [JSON Schema tooling page](https://json-schema.org/tools), which imply a recognized level of compliance.
If you believe an included implementation does not meet these criteria, please [open an issue](https://github.com/sourcemeta-research/jsonschema-benchmark/issues).

## Adding a new implementation

First, each implementation must have a `Dockerfile` that copies in any necessary scripts and installs dependencies.
There is also a `version.sh` script that must output the version of the implementation (often extracted from whatever dependency management tool is used).
If [Bowtie](https://bowtie.report) tests the implementation, a one-line `bowtie` file gives its Bowtie ID (for example `rust-boon`), so that the results site can link to its compliance results; leave it out otherwise.
The container must print a single line of nanosecond measurements, `cold,warm,compile,parse` (the cold and warm validation runs, the schema compilation, and the parsing of all instances from memory, so that the parse figure excludes file I/O), to standard output and exit with a non-zero status if any instance fails to validate.
Finally, appropriate targets must be added to the `Makefile` to build the Docker container and run the benchmark.
We will gladly accept pull requests to add new implementations.

## Results

The most recent results can be seen (via GitHub Actions)[https://github.com/sourcemeta-research/jsonschema-benchmark/actions/workflows/ci.yml].
Each run also builds an interactive results site from `report.csv`: an overall ranking, a schema-by-implementation matrix, per-schema detail and a head-to-head comparison of any two implementations, for any of the figures below.
It is a single HTML file in the run's `report` artifact (`site/index.html`), and is linked from the run's summary when the plots are uploaded.
The latest run on the runner pool is always at <https://sourcemeta-research-jsonschema-benchmark.s3.eu-central-003.backblazeb2.com/latest/index.html>.
The data behind it is beside it as `latest/data.json`, in the format described by [`site/data.schema.json`](site/data.schema.json), for other sites to build on.
When the `RESULTS_PAGES` variable is `true` and Pages deploys from GitHub Actions, the latest run on the runner pool is also published as the repository's GitHub Pages site.
The site needs no change when an implementation or a schema is added: implementations are named by their directory and grouped by the language of their source files.
To build it locally from a report, run `uv run python site/generate_site.py` after the report is in `dist/report.csv` (and, optionally, `./dataset_summary.sh csv > dist/summary.csv`).

Note that while there is noise in the results across runs due to the use of shared infrastructure, the relative ranking of different implementations is generally consistent.
The scheduled runs (and manual runs) execute on a pool of identical Azure VMs, so every implementation is measured on the same CPU model and results compare across runs; pull requests and pushes run on GitHub's hosted runners, whose CPU models vary from job to job. See [infra/runner-pool](infra/runner-pool/README.md).
It also worth noting that some implementations compile schemas ahead of time into a more efficient representation, while others interpret the entire schema at runtime.
Currently we operate under the assumption that a schema changes infrequently enough that the compilation process is unlikely to be a performance bottleneck.
As such, we currently only measure the time for validation and exclude any compilation time.
The time to parse the instances is also excluded from the validation time and reported separately in the `parse_ns` column; every implementation reads the instance file into memory before the timed parse, so `parse_ns` excludes file I/O.
Those four figures are all that an implementation reports and all that `report.csv` holds. The summary script (`.github/csv_md.py`) derives `cold_parse_ns` (`parse_ns` + `cold_ns`) and `warm_parse_ns` (`parse_ns` + `warm_ns`), the cost of parsing and validating every instance once from a cold start and at steady state, which is what a service validating each request pays, and `compile_cold_parse_ns` (`compile_ns` + `parse_ns` + `cold_ns`), the entire cold start path from an uncompiled schema to every instance validated once.
All measurements are totals over every instance of a schema; "cold" is the first validation pass of the process after the schema is compiled, so it includes neither the compilation time nor process start-up.
