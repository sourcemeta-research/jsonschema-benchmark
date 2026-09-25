<?php
require "vendor/autoload.php";

use Opis\JsonSchema\{
    CompliantValidator,
    ValidationResult,
    Errors\ErrorFormatter,
};

define('WARMUP_ITERATIONS', 100);
define('MAX_WARMUP_TIME', 1e9 * 10);

function validate_all(CompliantValidator $validator, $schema_id, $instances) {
  $valid = true;
  foreach ($instances as $instance) {
    $valid &= $validator->validate($instance, $schema_id)->isValid();
  }
  return $valid;
}

$schema_path = $argv[1];
$schema_id = "https://example.com/" . basename($schema_path);

// Create a new validator
$validator = new CompliantValidator();

// Register our schema
$compile_start = hrtime(true);
$validator->resolver()->registerFile(
    $schema_id,
    $schema_path . DIRECTORY_SEPARATOR . 'schema-noformat.json'
);
$compile_end = hrtime(true);
$compile_duration = $compile_end - $compile_start;

// Load data
$lines = file($schema_path . DIRECTORY_SEPARATOR . 'instances.jsonl');

$parse_start = hrtime(true);
$instances = [];
foreach ($lines as $line) {
    $instances[] = json_decode($line);
}
$parse_end = hrtime(true);
$parse_duration = $parse_end - $parse_start;

$cold_start = hrtime(true);
$result = validate_all($validator, $schema_id, $instances);
if (!$result) {
  exit(1);
}
$cold_end = hrtime(true);
$cold_duration = $cold_end - $cold_start;

$iterations = ceil(MAX_WARMUP_TIME / $cold_duration);
for ($i = 0; $i < min(WARMUP_ITERATIONS, $iterations); $i++) {
  validate_all($validator, $schema_id, $instances);
}

$warm_start = hrtime(true);
validate_all($validator, $schema_id, $instances);
$warm_end = hrtime(true);
$warm_duration = $warm_end - $warm_start;

echo $cold_duration . ',' . $warm_duration . ',' . $compile_duration . ',' . $parse_duration . "\n";
