require 'json_schemer'
require 'json'


path = ARGV[0]

# Load the schema and build a validator
schema = JSON.parse(File.read(File.join(path, "schema.json")))
schemer = JSONSchemer.schema(schema)

# Read all instances into an array
instances = File.open(File.join(path, "instances.jsonl")).map do |line|
  JSON.parse(line)
end

# Run the validation
start_time = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
instances.each do |instance|
  if !schemer.valid?(instance) then exit! end
end
end_time = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)

puts end_time - start_time
