using Corvus.Json;
using System.Diagnostics;
using System.Linq;

const int WarmupIterations = 1000;
const long MaxWarmupTime = 10_000_000_000;

bool ValidateAll(JSB.Schema[] docs) {
  var valid = true;
  foreach (var doc in docs) {
    var result = doc.Validate(ValidationContext.ValidContext, ValidationLevel.Flag);
    valid = valid && result.IsValid;
  }

  return valid;
}


// Read and parse all instances
var lines = File.ReadLines(args[0]);
var docs = lines.Select(l => JSB.Schema.Parse(l)).ToArray();

Stopwatch stopWatch = new Stopwatch();

// Loop and validate all instances
stopWatch.Start();
var valid = ValidateAll(docs);
stopWatch.Stop();
TimeSpan coldTs = stopWatch.Elapsed;

var iterations = (int) Math.Ceiling(((double) MaxWarmupTime) / coldTs.TotalNanoseconds);
for (int i = 0; i < Math.Min(iterations, WarmupIterations); i++) {
  ValidateAll(docs);
}

stopWatch.Restart();
ValidateAll(docs);
stopWatch.Stop();
TimeSpan warmTs = stopWatch.Elapsed;

// Output file time and exit
Console.WriteLine(coldTs.TotalNanoseconds + "," + warmTs.TotalNanoseconds);
Environment.Exit(valid ? 0 : 1);
