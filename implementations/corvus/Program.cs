using System.Diagnostics;
using Corvus.Text.Json;
using Corvus.Text.Json.RuntimeEvaluator;

// Mirrors the Blaze benchmark (implementations/blaze/main.cc): parse every instance
// up front, compile the schema once, validate all instances cold, warm up, then
// validate all instances once more warm. Prints cold,warm,compile in nanoseconds.
const int WarmupIterations = 100;
const long MaxWarmupTime = 10_000_000_000;

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
    var instances = new ParsedJsonDocument<JsonElement>[lines.Length];
    for (int i = 0; i < lines.Length; i++)
    {
        instances[i] = ParsedJsonDocument<JsonElement>.Parse(lines[i]);
    }

    // Compile the schema into the runtime evaluator's program
    var options = new JsonSchemaEvaluatorOptions
    {
        // The benchmark schemas have format stripped; match the other implementations
        AssertFormat = false,
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

    long iterations = 1 + ((MaxWarmupTime - 1) / Math.Max(cold, 1));
    for (long i = 0; i < Math.Min(iterations, WarmupIterations); i++)
    {
        ValidateAll(evaluator, instances);
    }

    long warmStart = Stopwatch.GetTimestamp();
    ValidateAll(evaluator, instances);
    long warmEnd = Stopwatch.GetTimestamp();

    Console.WriteLine($"{cold},{Nanoseconds(warmStart, warmEnd)},{Nanoseconds(compileStart, compileEnd)}");

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
