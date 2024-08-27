const Ajv = require('ajv');
const draft4schema = require('ajv/lib/refs/json-schema-draft-04.json');
const fs = require('fs');
const { performance } = require('perf_hooks');

function readJSONFile(filePath) {
  try {
    const fileContent = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(fileContent);
  } catch (error) {
    process.exit(1);
  }
}

function validateSchema(schemaPath, instancePath) {
  const schema = readJSONFile(schemaPath);
  const instance = readJSONFile(instancePath);

  const ajv = new Ajv({
    schemaId: 'id',
    meta: false,
    validateSchema: false
  });

  ajv.addMetaSchema(draft4schema);
  const validate = ajv.compile(schema);

  const startTime = performance.now();
  if (!validate(instance)) {
    process.exit(1);
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

validateSchema(schemaPath, instancePath);
