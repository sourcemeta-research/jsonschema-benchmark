<?php
// The jsonschema-benchmark entry point for justinrainbow/json-schema: read the instances into memory, parse each
// (timed), prepare the schema (timed), validate every instance once cold, warm up, validate once more warm. Prints
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
require __DIR__ . "/vendor/autoload.php";

use JsonSchema\Constraints\Constraint;
use JsonSchema\Constraints\Factory;
use JsonSchema\SchemaStorage;
use JsonSchema\Validator;

define('WARMUP_ITERATIONS', 100);
define('MAX_WARMUP_TIME', 1e9 * 10);

function validate_all(Validator $validator, $schema, int $mode, array $instances, bool $report): bool {
  $valid = true;
  foreach ($instances as $index => $instance) {
    $validator->reset();
    $validator->validate($instance, $schema, $mode);
    if (!$validator->isValid()) {
      if ($report) {
        fwrite(STDERR, "Error validating instance $index\n");
      }
      $valid = false;
    }
  }
  return $valid;
}

if ($argc !== 3) {
  fwrite(STDERR, "Usage: main.php <schema.json> <instances.jsonl>\n");
  exit(1);
}

$schema = json_decode(file_get_contents($argv[1]));
$lines = array_values(array_filter(file($argv[2], FILE_IGNORE_NEW_LINES), fn($line) => $line !== ''));

$parse_start = hrtime(true);
$instances = [];
foreach ($lines as $line) {
  $instances[] = json_decode($line);
}
$parse_end = hrtime(true);

// Draft 6 and 7 need the strict mode (as in Bowtie's harness); the benchmark's schemas have format removed.
$compile_start = hrtime(true);
$storage = new SchemaStorage();
$storage->addSchema('https://jsonschema-benchmark.example/schema.json', $schema);
$validator = new Validator(new Factory($storage));
$dialect = rtrim($schema->{'$schema'} ?? '', '#');
$mode = in_array($dialect, ['http://json-schema.org/draft-06/schema', 'http://json-schema.org/draft-07/schema',
                            'https://json-schema.org/draft/2019-09/schema'], true)
  ? Constraint::CHECK_MODE_NORMAL | Constraint::CHECK_MODE_STRICT
  : Constraint::CHECK_MODE_NORMAL;
$compile_end = hrtime(true);

$cold_start = hrtime(true);
$valid = validate_all($validator, $schema, $mode, $instances, true);
$cold_end = hrtime(true);
$cold_duration = $cold_end - $cold_start;

$iterations = ceil(MAX_WARMUP_TIME / max($cold_duration, 1));
for ($i = 0; $i < min(WARMUP_ITERATIONS, $iterations); $i++) {
  validate_all($validator, $schema, $mode, $instances, false);
}

$warm_start = hrtime(true);
validate_all($validator, $schema, $mode, $instances, false);
$warm_end = hrtime(true);

echo $cold_duration . ',' . ($warm_end - $warm_start) . ',' . ($compile_end - $compile_start) . ',' . ($parse_end - $parse_start) . "\n";
exit($valid ? 0 : 1);
