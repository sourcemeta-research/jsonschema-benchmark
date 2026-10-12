using System.Diagnostics;
using Corvus.Text.Json;
using Corvus.Text.Json.RuntimeEvaluator;

// Corvus on the JIT, with the evaluator's runtime code generation: the configuration for a long-lived process.
// (corvus-net-optcold is the native AOT build, which starts fastest and interprets the schema.)
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

static bool ValidateAll(JsonSchemaEvaluator evaluator, ParsedJsonDocument<JsonElement>[] instances)
{
    for (int i = 0; i < instances.Length; i++)
    {
        if (!evaluator.Evaluate(instances[i].RootElement))
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
    byte[] schema = File.ReadAllBytes(schemaPath);
    ReadOnlyMemory<byte>[] lines = ReadLines(File.ReadAllBytes(instancesPath));

    // Parse every instance (the instances are UTF-8 JSON, one per line)
    long parseStart = Stopwatch.GetTimestamp();
    var instances = new ParsedJsonDocument<JsonElement>[lines.Length];
    for (int i = 0; i < lines.Length; i++)
    {
        instances[i] = ParsedJsonDocument<JsonElement>.Parse(lines[i]);
    }

    long parseEnd = Stopwatch.GetTimestamp();

    // Compile the schema into the runtime evaluator's program
    var options = new JsonSchemaEvaluatorOptions
    {
        // The benchmark schemas have format stripped; match the other implementations
        AssertFormat = false,

        // Compile the schema to IL before the first evaluation, which pays for it (the cold figure).
        CodeGeneration = JsonSchemaCodeGeneration.Eager,
    };

    long compileStart = Stopwatch.GetTimestamp();
    using JsonSchemaEvaluator evaluator = JsonSchemaEvaluator.Compile(schema, options);
    long compileEnd = Stopwatch.GetTimestamp();

    long coldStart = Stopwatch.GetTimestamp();
    if (!ValidateAll(evaluator, instances))
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
        ValidateAll(evaluator, instances);
        warm = Nanoseconds(passStart, Stopwatch.GetTimestamp());
    }

    Console.WriteLine($"{cold},{warm},{Nanoseconds(compileStart, compileEnd)},{Nanoseconds(parseStart, parseEnd)}");

    foreach (ParsedJsonDocument<JsonElement> instance in instances)
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
