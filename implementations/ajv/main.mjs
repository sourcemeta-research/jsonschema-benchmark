import Ajv from 'ajv';
import draft4schema from 'ajv/lib/refs/json-schema-draft-04.json' assert { type: 'json' };
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

  const ajv = new Ajv({
    schemaId: 'id',
    meta: false,
    validateSchema: false
  });

  ajv.addMetaSchema(draft4schema);
  const validate = ajv.compile(schema);

  const instances = [];
  for await (const instance of readJSONLines(instancePath)) {
    instances.push(instance);
  }
  const startTime = performance.now();
  for (const instance of instances) {
    if (!validate(instance)) {
      process.exit(1);
    }
  }

  const endTime = performance.now();

  const durationNs = (endTime - startTime) * 1e6;
  console.log(durationNs.toFixed(0));
}

if (process.argv.length !== 4) {
  process.exit(1);
}

const schemaPath = process.argv[2];
const instancePath = process.argv[3];

await validateSchema(schemaPath, instancePath);
