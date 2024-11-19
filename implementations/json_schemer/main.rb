require 'json_schemer'
require 'json'


WARMUP_ITERATIONS = 100
MAX_WARMUP_TIME = 1e9 * 10

def validate_all(instances, schemer)
  instances.each do |instance|
    if !schemer.valid?(instance) then exit! end
  end
end

path = ARGV[0]

# Load the schema and build a validator
schema = JSON.parse(File.read(File.join(path, "schema.json")))

compile_start = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
schemer = JSONSchemer.schema(schema)
compile_end = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)

# Read all instances into an array
instances = File.open(File.join(path, "instances.jsonl")).map do |line|
  JSON.parse(line)
end

# Run the validation
cold_start = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
validate_all(instances, schemer)
cold_end = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)

iterations = (MAX_WARMUP_TIME / (cold_end - cold_start)).ceil

[WARMUP_ITERATIONS, iterations].min.times do
  validate_all(instances, schemer)
end

warm_start = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
validate_all(instances, schemer)
warm_end = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)

print (cold_end - cold_start), ",", (warm_end - warm_start), ",", (compile_end - compile_start), "\n"
