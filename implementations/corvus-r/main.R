# The jsonschema-benchmark entry point for Corvus.JsonSchema's R package (corvusjsonschema), which validates R values
# in place with the corvus-json-schema Rust crate.
#
#   main.R <schema.json> <instances.jsonl>
#
# Mirrors the other implementations: read the instance file, parse every instance (timed, with jsonlite, into the R
# values the package reads in place), compile the schema (timed), validate every instance once cold, warm up,
# validate once more warm. Prints one line "cold,warm,compile,parse" in nanoseconds and exits non-zero if any
# instance is invalid.
library(corvusjsonschema)

warmup_iterations <- 100
max_warmup_time <- 10e9 # 10 seconds

now <- function() as.numeric(Sys.time()) * 1e9
# The first call of Sys.time loads the time zone data: not something to time.
invisible(now())

arguments <- commandArgs(trailingOnly = TRUE)
schema <- paste(readLines(arguments[1], warn = FALSE, encoding = "UTF-8"), collapse = "\n")
lines <- readLines(arguments[2], warn = FALSE, encoding = "UTF-8")
lines <- lines[nzchar(lines)]

validate_all <- function(validator, instances) {
  valid <- TRUE
  for (instance in instances) if (!is_valid(validator, instance)) valid <- FALSE
  valid
}

parse_start <- now()
instances <- lapply(lines, jsonlite::fromJSON, simplifyVector = FALSE)
parse <- now() - parse_start

# The benchmark's schema-noformat.json has no `format` keywords; the defaults leave `format` as an annotation.
compile_start <- now()
validator <- compile_schema(schema)
compile <- now() - compile_start

cold_start <- now()
valid <- validate_all(validator, instances)
cold <- now() - cold_start

iterations <- min(ceiling(max_warmup_time / max(cold, 1)), warmup_iterations)
for (i in seq_len(iterations)) validate_all(validator, instances)

warm_start <- now()
valid <- validate_all(validator, instances) && valid
warm <- now() - warm_start

cat(sprintf("%.0f,%.0f,%.0f,%.0f\n", cold, warm, compile, parse))
quit(save = "no", status = if (valid) 0L else 1L)
