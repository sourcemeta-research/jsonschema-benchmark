using System.Diagnostics;
using System.Text.Json;
using Corvus.Json;
using Corvus.Json.Validator;

// Corvus.JsonSchema's V4 engine (Corvus.Json.Validator), which generates C# for the schema and compiles it with
// Roslyn: the engine behind Corvus.Json's generated types. (corvus-net-optwarm and corvus-net-optcold are the V5
// engine, Corvus.Text.Json.)
//
// Parses every instance up front, compiles the schema once, validates all instances cold, warms up, and reports
// the last warm-up pass as warm. Prints cold,warm,compile,parse in nanoseconds.
//
// The warm-up runs for a set time, not a set number of passes: a JIT recompiles hot code in the background as its
// profile fills in, and a hundred passes of a small corpus end before it has. The warm figure is a pass inside the
// loop because a separate call made after the loop is a new call site, which the JIT has not yet optimised.
const int MinWarmupIterations = 100;
const long WarmupTime = 2_000_000_000;

if (args.Length < 2)
{
    Console.Error.WriteLine("Usage: bench <schema> <instances>");
    return 1;
}

try
{
    return Validate(args[0], args[1]);
}
catch (Exception e)
{
    Console.Error.WriteLine($"Error during Corvus benchmark: {e.Message}");
    return 1;
}

static bool ValidateAll(JsonSchema schema, JsonDocument[] instances)
{
    for (int i = 0; i < instances.Length; i++)
    {
        if (!schema.Validate(instances[i].RootElement).IsValid)
        {
            Console.Error.WriteLine($"Error validating instance {i}");
            return false;
        }
    }

    return true;
}

static long Nanoseconds(long start, long end)
{
    return (long)((end - start) * (1_000_000_000.0 / Stopwatch.Frequency));
}

static int Validate(string schemaPath, string instancesPath)
{
    string schemaText = File.ReadAllText(schemaPath);
    ReadOnlyMemory<byte>[] lines = ReadLines(File.ReadAllBytes(instancesPath));

    // Parse every instance (the instances are UTF-8 JSON, one per line)
    long parseStart = Stopwatch.GetTimestamp();
    var instances = new JsonDocument[lines.Length];
    for (int i = 0; i < lines.Length; i++)
    {
        instances[i] = JsonDocument.Parse(lines[i]);
    }

    long parseEnd = Stopwatch.GetTimestamp();

    // Generate and compile the schema's types. The benchmark schemas have format stripped; V4 asserts format by
    // default, so turn that off to match the other implementations.
    var options = new JsonSchema.Options(alwaysAssertFormat: false);

    long compileStart = Stopwatch.GetTimestamp();
    JsonSchema schema = JsonSchema.FromText(schemaText, "https://jsonschema-benchmark.example/schema.json", options);
    long compileEnd = Stopwatch.GetTimestamp();

    long coldStart = Stopwatch.GetTimestamp();
    if (!ValidateAll(schema, instances))
    {
        return 1;
    }

    long coldEnd = Stopwatch.GetTimestamp();
    long cold = Nanoseconds(coldStart, coldEnd);

    long warm = cold;
    long warmupStart = Stopwatch.GetTimestamp();
    for (long i = 0; i < MinWarmupIterations || Nanoseconds(warmupStart, Stopwatch.GetTimestamp()) < WarmupTime; i++)
    {
        long passStart = Stopwatch.GetTimestamp();
        ValidateAll(schema, instances);
        warm = Nanoseconds(passStart, Stopwatch.GetTimestamp());
    }

    Console.WriteLine($"{cold},{warm},{Nanoseconds(compileStart, compileEnd)},{Nanoseconds(parseStart, parseEnd)}");

    foreach (JsonDocument instance in instances)
    {
        instance.Dispose();
    }

    return 0;
}

// Splits a JSONL file into one UTF-8 slice per non-empty line
static ReadOnlyMemory<byte>[] ReadLines(byte[] jsonl)
{
    var lines = new List<ReadOnlyMemory<byte>>();
    int start = 0;
    for (int i = 0; i <= jsonl.Length; i++)
    {
        if (i == jsonl.Length || jsonl[i] == (byte)'\n')
        {
            int end = i;
            if (end > start && jsonl[end - 1] == (byte)'\r')
            {
                end--;
            }

            if (end > start)
            {
                lines.Add(new ReadOnlyMemory<byte>(jsonl, start, end - start));
            }

            start = i + 1;
        }
    }

    return lines.ToArray();
}
