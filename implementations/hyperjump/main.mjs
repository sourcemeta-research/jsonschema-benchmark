import { registerSchema, validate } from "@hyperjump/json-schema/draft-2020-12";
import fs from 'fs';
import { performance } from 'perf_hooks';

const WARMUP_ITERATIONS = 100;
const MAX_WARMUP_TIME = 1e9 * 10; // 10 seconds

await Promise.all([
  import("@hyperjump/json-schema/draft-2019-09"),
  import("@hyperjump/json-schema/draft-07"),
]);

function readJSONFile(filePath) {
  try {
    const fileContent = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(fileContent);
  } catch (error) {
    process.exit(1);
  }
}

function readLines(filePath) {
  return fs.readFileSync(filePath, 'utf8').split('\n').filter((line) => line.length > 0);
}

async function validateAll(instances, schemaId) {
  let failed = false;
  for (const instance of instances) {
    const output = await validate(schemaId, instance);
    if (!output.valid) {
      failed = true;
    }
  }
  return failed;
}

async function validateSchema(schemaPath, instancePath) {
  const schema = readJSONFile(schemaPath);

  const schemaId = schema["$id"] || "https://example.com" + schemaPath;

  const compileStart = performance.now();
  registerSchema(schema, schemaId);
  const compiled = await validate(schemaId);
  const compileEnd = performance.now();
  const compileDurationNs = (compileEnd - compileStart) * 1e6;

  const lines = readLines(instancePath);

  const parseStart = performance.now();
  const instances = lines.map((line) => JSON.parse(line));
  const parseEnd = performance.now();
  const parseDurationNs = (parseEnd - parseStart) * 1e6;

  const coldStartTime = performance.now();
  const failed = await validateAll(instances, schemaId);
  const coldEndTime = performance.now();
  const coldDurationNs = (coldEndTime - coldStartTime) * 1e6;

  const iterations = Math.ceil(MAX_WARMUP_TIME / coldDurationNs);
  for (let i = 0; i < Math.min(iterations, WARMUP_ITERATIONS); i++) {
    await validateAll(instances, schemaId);
  }

  const warmStartTime = performance.now();
  await validateAll(instances, schemaId);
  const warmEndTime = performance.now();
  const warmDurationNs = (warmEndTime - warmStartTime) * 1e6;

  console.log(coldDurationNs.toFixed(0) + ',' + warmDurationNs.toFixed(0) + ',' + compileDurationNs.toFixed(0) + ',' + parseDurationNs.toFixed(0));

  // Exit with non-zero status on validation failure
  if (failed) {
    process.exit(1);
  }
}

if (process.argv.length !== 4) {
  process.exit(1);
}

const schemaPath = process.argv[2];
const instancePath = process.argv[3];

await validateSchema(schemaPath, instancePath);
