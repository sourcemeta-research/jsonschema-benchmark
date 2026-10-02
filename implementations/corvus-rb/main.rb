# The jsonschema-benchmark entry point for Corvus.JsonSchema's Ruby gem (corvus_json_schema), which validates Ruby
# values in place with the corvus-json-schema Rust crate.
#
#   main.rb <schema.json> <instances.jsonl>
#
# Mirrors the other implementations: read the instance file, parse every instance (timed), compile the schema
# (timed), validate every instance once cold, warm up, validate once more warm. Prints one line
# "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
require "json"
require "corvus_json_schema"

WARMUP_ITERATIONS = 100
MAX_WARMUP_TIME = 10_000_000_000 # 10 seconds

def now
  Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
end

def validate_all(validator, instances)
  valid = true
  instances.each { |instance| valid = false unless validator.valid?(instance) }
  valid
end

schema = JSON.parse(File.read(ARGV[0]))
lines = File.readlines(ARGV[1], chomp: true).reject(&:empty?)

parse_start = now
instances = lines.map { |line| JSON.parse(line) }
parse = now - parse_start

# The benchmark's schema-noformat.json has no `format` keywords; the defaults leave `format` as an annotation.
compile_start = now
validator = CorvusJsonSchema.compile(schema)
compile = now - compile_start

cold_start = now
valid = validate_all(validator, instances)
cold = now - cold_start

iterations = (MAX_WARMUP_TIME.to_f / [cold, 1].max).ceil
[iterations, WARMUP_ITERATIONS].min.times { validate_all(validator, instances) }

warm_start = now
validate_all(validator, instances)
warm = now - warm_start

puts "#{cold},#{warm},#{compile},#{parse}"
exit(valid ? 0 : 1)
