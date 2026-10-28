<?php
require __DIR__ . "/vendor/autoload.php";

use JsonSchema\{
    DraftIdentifiers,
    SchemaStorage,
    Validator,
    Constraints\Constraint,
    Constraints\Factory,
};

define('WARMUP_ITERATIONS', 100);
define('MAX_WARMUP_TIME', 1e9 * 10);

function validate_all(Validator $validator, $schema, $instances) {
  $valid = true;
  foreach ($instances as $instance) {
    $valid &= $validator->validate($instance, $schema) === Validator::ERROR_NONE;
  }
  return $valid;
}

$schema_path = $argv[1];

// Load the schema and data
$schema_json = file_get_contents($schema_path . DIRECTORY_SEPARATOR . 'schema-noformat.json');
$lines = file($schema_path . DIRECTORY_SEPARATOR . 'instances.jsonl');

// Register our schema, resolving its references, and create a validator
// for its dialect (strict mode uses the draft-specific constraints)
$compile_start = hrtime(true);
$schema_object = json_decode($schema_json);
// References resolve against the schema's own identifier, so register it under that
$schema_id = $schema_object->{'$id'} ?? $schema_object->id ?? "https://example.com/" . basename($schema_path);
$schema_storage = new SchemaStorage();
$schema_storage->addSchema($schema_id, $schema_object);
$factory = new Factory($schema_storage, null, Constraint::CHECK_MODE_STRICT);
$factory->setDefaultDialect($schema_object->{'$schema'} ?? DraftIdentifiers::DRAFT_7);
$validator = new Validator($factory);
$schema = (object) ['$ref' => $schema_id];
$compile_end = hrtime(true);
$compile_duration = $compile_end - $compile_start;

$parse_start = hrtime(true);
$instances = [];
foreach ($lines as $line) {
    $instances[] = json_decode($line);
}
$parse_end = hrtime(true);
$parse_duration = $parse_end - $parse_start;

$cold_start = hrtime(true);
$result = validate_all($validator, $schema, $instances);
if (!$result) {
  exit(1);
}
$cold_end = hrtime(true);
$cold_duration = $cold_end - $cold_start;

$iterations = ceil(MAX_WARMUP_TIME / $cold_duration);
for ($i = 0; $i < min(WARMUP_ITERATIONS, $iterations); $i++) {
  validate_all($validator, $schema, $instances);
}

$warm_start = hrtime(true);
validate_all($validator, $schema, $instances);
$warm_end = hrtime(true);
$warm_duration = $warm_end - $warm_start;

echo $cold_duration . ',' . $warm_duration . ',' . $compile_duration . ',' . $parse_duration . "\n";
