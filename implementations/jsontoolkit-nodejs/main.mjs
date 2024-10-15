import { compile, evaluate } from './repo/bindings/nodejs/jsontoolkit.js';

import fs from 'fs';
import readline from 'readline';
import { performance } from 'perf_hooks';

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

async function validateSchema(schemaPath, instancePath) {
  const schema = readJSONFile(schemaPath);
  const schemaId = await compile(schema);

  const instances = [];
  for await (const instance of readJSONLines(instancePath)) {
    instances.push(instance);
  }
  let failed = false;
  const startTime = performance.now();
  for (const instance of instances) {
    const valid = await evaluate(schemaId, instance);
    if (!valid) {
      failed = true;
    }
  }

  const endTime = performance.now();

  const durationNs = (endTime - startTime) * 1e6;
  console.log(durationNs.toFixed(0));

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
