import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { performance } from 'perf_hooks';

const DRAFTS = {
  "https://json-schema.org/draft/2020-12/schema": (await import("ajv/dist/2020.js")).Ajv2020,
  "https://json-schema.org/draft/2019-09/schema": (await import("ajv/dist/2019.js")).Ajv2019,
  "http://json-schema.org/draft-07/schema": (await import("ajv")).Ajv,
};

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

  const ajv = new DRAFTS[schema['$schema'].replace(/#$/, '')]({strict: false});

  const compileStart = performance.now();
  const validate = ajv.compile(schema);
  const compileEnd = performance.now();
  const compileDurationNs = (compileEnd - compileStart) * 1e6;

  const instances = [];
  for await (const instance of readJSONLines(instancePath)) {
    instances.push(instance);
  }
  let failed = false;
  const startTime = performance.now();
  for (const instance of instances) {
    if (!validate(instance)) {
      failed = true;
    }
  }

  const endTime = performance.now();

  const durationNs = (endTime - startTime) * 1e6;
  console.log(durationNs.toFixed(0) + ',' + compileDurationNs.toFixed(0));

  // Exit with non-zero status on validation failure
  if (failed) {
    process.exit(1);
  }
}

if (process.argv.length !== 3) {
  process.exit(1);
}

const schemaPath = path.join(process.argv[2], "schema.json");
const instancePath = path.join(process.argv[2], "/instances.jsonl");

await validateSchema(schemaPath, instancePath);
