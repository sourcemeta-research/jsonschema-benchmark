import fs from 'fs';
import { performance } from 'perf_hooks';
import languageService from 'vscode-json-languageservice';

// A CommonJS package, so its exports come through the default import.
const { DiagnosticSeverity, getLanguageService, SchemaDraft, TextDocument } = languageService;

const DRAFTS = {
  "https://json-schema.org/draft/2020-12/schema": SchemaDraft.v2020_12,
  "https://json-schema.org/draft/2019-09/schema": SchemaDraft.v2019_09,
  "http://json-schema.org/draft-07/schema": SchemaDraft.v7,
};

const ls = getLanguageService({});

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

// The language service validates its own syntax tree of a text document, so parsing makes those.
let next = 0;
const parse = (line) => {
  const document = TextDocument.create(`example://instance-${next++}.json`, 'json', 0, line);
  return { document, tree: ls.parseJSONDocument(document) };
};
async function validateAll(instances, validator) {
  let failed = false;
  for (const instance of instances) {
    if (!(await validator(instance))) {
      failed = true;
    }
  }

  return failed;
}

async function validateSchema(schemaPath, instancePath) {
  const schema = readJSONFile(schemaPath);

  // The language service takes the schema with each validation and prepares it then; there is no separate step,
  // so the compile figure is only setting up the options. It reports schema validation failures as warnings unless
  // told to make them errors, and also warns of things that are not failures, such as a deprecated property; so
  // failures are made errors, and only errors make an instance invalid.
  const compileStart = performance.now();
  const settings = { schemaDraft: DRAFTS[schema['$schema'].replace(/#$/, '')], schemaValidation: 'error' };
  const validate = async (instance) =>
    !(await ls.doValidation(instance.document, instance.tree, settings, schema))
      .some((diagnostic) => diagnostic.severity === DiagnosticSeverity.Error);
  const compileEnd = performance.now();
  const compileDurationNs = (compileEnd - compileStart) * 1e6;

  const lines = readLines(instancePath);

  const parseStart = performance.now();
  const instances = lines.map((line) => parse(line));
  const parseEnd = performance.now();
  const parseDurationNs = (parseEnd - parseStart) * 1e6;

  const coldStartTime = performance.now();
  const failed = await validateAll(instances, validate);
  const coldEndTime = performance.now();
  const coldDurationNs = (coldEndTime - coldStartTime) * 1e6;

  const iterations = Math.ceil(MAX_WARMUP_TIME / coldDurationNs);
  for (let i = 0; i < Math.min(iterations, WARMUP_ITERATIONS); i++) {
    await validateAll(instances, validate);
  }

  const warmStartTime = performance.now();
  await validateAll(instances, validate);
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
