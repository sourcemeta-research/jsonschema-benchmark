using Json.Schema;
using System.Diagnostics;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Nodes;

const int WarmupIterations = 1000;
const long MaxWarmupTime = 10_000_000_000;

bool ValidateAll(JsonSchema schema, JsonNode[] docs) {
  var valid = true;
  foreach (var doc in docs) {
    var result = schema.Evaluate(doc);
    valid = valid && result.IsValid;
  }

  return valid;
}

Stopwatch stopWatch = new Stopwatch();

// Load the schema
stopWatch.Start();
var schema = JsonSchema.FromFile(args[0]);
stopWatch.Stop();
TimeSpan compileTs = stopWatch.Elapsed;

// Read and parse all instances
var lines = File.ReadLines(args[1]);
var docs = lines.Select(l => JsonNode.Parse(l)).ToArray();

// Loop and validate all instances
stopWatch.Start();
var valid = ValidateAll(schema, docs);
stopWatch.Stop();
TimeSpan coldTs = stopWatch.Elapsed;

var iterations = (int) Math.Ceiling(((double) MaxWarmupTime) / coldTs.TotalNanoseconds);
for (int i = 0; i < Math.Min(iterations, WarmupIterations); i++) {
  ValidateAll(schema, docs);
}

stopWatch.Restart();
ValidateAll(schema, docs);
stopWatch.Stop();
TimeSpan warmTs = stopWatch.Elapsed;

// Output file time and exit
Console.WriteLine(coldTs.TotalNanoseconds + "," + warmTs.TotalNanoseconds + "," + compileTs.TotalNanoseconds);
Environment.Exit(valid ? 0 : 1);
