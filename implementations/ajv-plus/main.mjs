import fs from 'fs';
import { performance } from 'perf_hooks';
const DRAFTS = {
  "https://json-schema.org/draft/2020-12/schema": (await import("@theflashlabs/ajv-plus/dist/2020.js")).default,
  "https://json-schema.org/draft/2019-09/schema": (await import("@theflashlabs/ajv-plus/dist/2019.js")).default,
  "http://json-schema.org/draft-07/schema": (await import("@theflashlabs/ajv-plus")).default,
};
function embeddedIds(schema, ids = []) {
  if (Array.isArray(schema)) {
    schema.forEach((item) => embeddedIds(item, ids));
  } else if (typeof schema === 'object' && schema !== null) {
    if (typeof schema['$id'] === 'string') {
      ids.push(schema['$id']);
    }
    Object.values(schema).forEach((value) => embeddedIds(value, ids));
  }
  return ids;
}


const WARMUP_ITERATIONS = 100;
const MAX_WARMUP_TIME = 1e9 * 10; // 10 seconds

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

const parse = (line) => JSON.parse(line);
function validateAll(instances, validator) {
  let failed = false;
  for (const instance of instances) {
    if (!validator(instance)) {
      failed = true;
    }
  }

  return failed;
}

async function validateSchema(schemaPath, instancePath) {
  const schema = readJSONFile(schemaPath);

  const Ajv = DRAFTS[schema['$schema'].replace(/#$/, '')];
  const ajv = new Ajv({ strict: false });

  // A schema that embeds its own copy of a meta-schema conflicts with ajv-plus's built-in copy
  for (const id of embeddedIds(schema)) {
    ajv.removeSchema(id);
  }

  const compileStart = performance.now();
  const validate = ajv.compile(schema);
  const compileEnd = performance.now();
  const compileDurationNs = (compileEnd - compileStart) * 1e6;

  const lines = readLines(instancePath);

  const parseStart = performance.now();
  const instances = lines.map((line) => parse(line));
  const parseEnd = performance.now();
  const parseDurationNs = (parseEnd - parseStart) * 1e6;

  const coldStartTime = performance.now();
  const failed = validateAll(instances, validate);
  const coldEndTime = performance.now();
  const coldDurationNs = (coldEndTime - coldStartTime) * 1e6;

  const iterations = Math.ceil(MAX_WARMUP_TIME / coldDurationNs);
  for (let i = 0; i < Math.min(iterations, WARMUP_ITERATIONS); i++) {
    validateAll(instances, validate);
  }

  const warmStartTime = performance.now();
  validateAll(instances, validate);
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
