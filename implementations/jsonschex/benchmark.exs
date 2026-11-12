# The jsonschema-benchmark entry point for JSONSchex (2020-12): read the instances into memory, parse each (timed),
# compile the schema (timed), validate every instance once cold, warm up, validate once more warm. Prints
# "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
warmup_iterations = 100
max_warmup_time = 10_000_000_000

[schema_path, instances_path] = System.argv()
schema = JSON.decode!(File.read!(schema_path))
lines = String.split(File.read!(instances_path), "\n", trim: true)

parse_start = System.monotonic_time(:nanosecond)
instances = Enum.map(lines, &JSON.decode!/1)
parse_duration = System.monotonic_time(:nanosecond) - parse_start

compile_start = System.monotonic_time(:nanosecond)
{:ok, compiled} = JSONSchex.compile(schema)
compile_duration = System.monotonic_time(:nanosecond) - compile_start

validate_all = fn ->
  Enum.reduce(instances, true, fn instance, valid ->
    JSONSchex.validate(compiled, instance) == :ok and valid
  end)
end

cold_start = System.monotonic_time(:nanosecond)
valid = validate_all.()
cold_duration = System.monotonic_time(:nanosecond) - cold_start

iterations = div(max_warmup_time + max(cold_duration, 1) - 1, max(cold_duration, 1))
Enum.each(1..min(iterations, warmup_iterations)//1, fn _ -> validate_all.() end)

warm_start = System.monotonic_time(:nanosecond)
validate_all.()
warm_duration = System.monotonic_time(:nanosecond) - warm_start

IO.puts("#{cold_duration},#{warm_duration},#{compile_duration},#{parse_duration}")
if not valid, do: System.halt(1)
