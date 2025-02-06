warmup_iterations = 100
max_warmup_time = 10000000000 # 10 seconds in ns

schema_path = Enum.at(System.argv(), 0)
{:ok, schema_string} = File.read(Path.join(schema_path, "schema-noformat.json"))
schema = Poison.Parser.parse!(schema_string, %{})

resolver = {JSV.Resolver.BuiltIn, allowed_prefixes: ["https://json-schema.org/", "http://json-schema.org/"]}

# Compile the schema
compile_start = System.monotonic_time(:nanosecond)
schema = JSV.build!(schema, resolver: resolver)
compile_end = System.monotonic_time(:nanosecond)
compile_duration = compile_end - compile_start

# Load instances
stream = File.stream!(Path.join(schema_path, "instances.jsonl"), [:read, :utf8])
instances = Enum.reduce stream, [], fn(line, listing) ->
  [Poison.Parser.parse!(line, %{}) | listing]
end

# Validate the data
cold_start = System.monotonic_time(:nanosecond)
Enum.each(instances, fn(instance) ->
  {:ok, _} = JSV.validate(instance, schema)
end)
cold_end = System.monotonic_time(:nanosecond)
cold_duration = cold_end - cold_start

iterations = trunc(Float.ceil(max_warmup_time / cold_duration))
Enum.each(0..min(iterations, warmup_iterations), fn(_) ->
  Enum.each(instances, fn(instance) ->
    {:ok, _} = JSV.validate(instance, schema)
  end)
end)

# Validate the data
warm_start = System.monotonic_time(:nanosecond)
Enum.each(instances, fn(instance) ->
  {:ok, _} = JSV.validate(instance, schema)
end)
warm_end = System.monotonic_time(:nanosecond)
warm_duration = warm_end - warm_start

IO.puts(Integer.to_string(cold_duration) <> "," <> Integer.to_string(warm_duration) <> "," <> Integer.to_string(compile_duration))
