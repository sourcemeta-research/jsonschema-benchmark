using Corvus.Json;
using System.Diagnostics;
using System.Linq;

// Read and parse all instances
var lines = File.ReadLines(args[0]);
var docs = lines.Select(l => JSB.Schema.Parse(l)).ToArray();

Stopwatch stopWatch = new Stopwatch();
stopWatch.Start();

// Loop and validate all instances
var valid = true;
foreach (var doc in docs) {
  var result = doc.Validate(ValidationContext.ValidContext, ValidationLevel.Flag);
  valid = valid && result.IsValid;
}

stopWatch.Stop();
TimeSpan ts = stopWatch.Elapsed;

// Output file time and exit
Console.WriteLine(ts.TotalNanoseconds);
Environment.Exit(valid ? 0 : 1);
