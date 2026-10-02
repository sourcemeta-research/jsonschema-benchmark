<?php
// The jsonschema-benchmark entry point for Corvus.JsonSchema's PHP extension (corvus_json_schema), which validates PHP
// values in place with the corvus-json-schema Rust crate.
//
//   main.php <schema.json> <instances.jsonl>
//
// Mirrors the other implementations: read the instance file, parse every instance (timed, with json_decode to
// objects, as for Opis), compile the schema (timed), validate every instance once cold, warm up, validate once more
// warm. Prints one line "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.

use Corvus\JsonSchema\Validator;

const WARMUP_ITERATIONS = 100;
const MAX_WARMUP_TIME = 10_000_000_000; // 10 seconds

function validate_all(Validator $validator, array $instances): bool
{
    $valid = true;
    foreach ($instances as $instance) {
        if (!$validator->isValid($instance)) {
            $valid = false;
        }
    }
    return $valid;
}

$schema = json_decode(file_get_contents($argv[1]));
$lines = file($argv[2], FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

$parse_start = hrtime(true);
$instances = [];
foreach ($lines as $line) {
    $instances[] = json_decode($line);
}
$parse = hrtime(true) - $parse_start;

// The benchmark's schema-noformat.json has no `format` keywords; the defaults leave `format` as an annotation.
$compile_start = hrtime(true);
$validator = Validator::compile($schema);
$compile = hrtime(true) - $compile_start;

$cold_start = hrtime(true);
$valid = validate_all($validator, $instances);
$cold = hrtime(true) - $cold_start;

$iterations = (int) ceil(MAX_WARMUP_TIME / max($cold, 1));
for ($i = 0; $i < min($iterations, WARMUP_ITERATIONS); $i++) {
    validate_all($validator, $instances);
}

$warm_start = hrtime(true);
validate_all($validator, $instances);
$warm = hrtime(true) - $warm_start;

echo "$cold,$warm,$compile,$parse\n";
exit($valid ? 0 : 1);
