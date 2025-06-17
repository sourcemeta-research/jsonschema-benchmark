import { validator } from '@exodus/schemasafe';
import fs from 'fs';
import readline from 'readline';
import { performance } from 'perf_hooks';

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

async function* readJSONLines(filePath) {
  const rl = readline.createInterface({
    input: fs.createReadStream(filePath),
  });
  for await (const line of rl) {
    yield JSON.parse(line);
  }
}

function validateAll(instances, validate) {
  let failed = false;
  for (const instance of instances) {
    if (!validate(instance)) {
      failed = true;
    }
  }

  return failed;
}

async function validateSchema(schemaPath, instancePath) {
  const schema = readJSONFile(schemaPath);

  const compileStart = performance.now();
  let validate;
  try {
    validate = validator(schema, {
      mode: 'spec',
      isJSON: true
    });
  } catch (error) {
    process.exit(1);
  }
  const compileEnd = performance.now();
  const compileDurationNs = (compileEnd - compileStart) * 1e6;

  const instances = [];
  for await (const instance of readJSONLines(instancePath)) {
    instances.push(instance);
  }

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

  console.log(coldDurationNs.toFixed(0) + ',' + warmDurationNs.toFixed(0) + ',' + compileDurationNs.toFixed(0));

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
