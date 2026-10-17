#include <nlohmann/json.hpp>
#include <valijson/adapters/nlohmann_json_adapter.hpp>
#include <valijson/schema.hpp>
#include <valijson/schema_parser.hpp>
#include <valijson/validator.hpp>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#define WARMUP_ITERATIONS 100L
#define MAX_WARMUP_TIME 10000000000

using nlohmann::json;
using valijson::adapters::NlohmannJsonAdapter;

// Valijson supports drafts 3, 4 and 7, and takes the draft as a parser option
valijson::SchemaParser::Version schema_version(const json &schema) {
  const std::string dialect = schema.value("$schema", "http://json-schema.org/draft-07/schema#");
  if (dialect.find("draft-03") != std::string::npos) {
    return valijson::SchemaParser::kDraft3;
  } else if (dialect.find("draft-04") != std::string::npos) {
    return valijson::SchemaParser::kDraft4;
  } else if (dialect.find("draft-07") != std::string::npos) {
    return valijson::SchemaParser::kDraft7;
  }

  throw std::runtime_error("Unsupported dialect " + dialect);
}

bool validate_all(valijson::Validator &validator, const valijson::Schema &schema, const std::vector<json> &instances) {
  bool valid = true;
  for (const auto &instance : instances) {
    valid &= validator.validate(schema, NlohmannJsonAdapter(instance), nullptr);
  }
  return valid;
}

int validate(const std::filesystem::path &example) {
  std::ifstream input_schema((example / "schema-noformat.json").string());
  const auto schema_document = json::parse(input_schema);

  const auto compile_start{std::chrono::high_resolution_clock::now()};
  valijson::Schema schema;
  valijson::SchemaParser parser(schema_version(schema_document));
  parser.populateSchema(NlohmannJsonAdapter(schema_document), schema);
  // The validator caches the regular expressions of the schema, so it is reused for every instance
  valijson::Validator validator;
  const auto compile_end{std::chrono::high_resolution_clock::now()};
  const auto compile_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      compile_end - compile_start)};

  std::ifstream input_instances((example / "instances.jsonl").string());
  std::vector<std::string> lines;
  std::string line;
  while (std::getline(input_instances, line)) {
    lines.push_back(line);
  }

  const auto parse_start{std::chrono::high_resolution_clock::now()};
  std::vector<json> instances;
  for (const auto &text : lines) {
    instances.push_back(json::parse(text));
  }
  const auto parse_end{std::chrono::high_resolution_clock::now()};
  const auto parse_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      parse_end - parse_start)};

  const auto cold_start{std::chrono::high_resolution_clock::now()};
  if (!validate_all(validator, schema, instances)) {
    return EXIT_FAILURE;
  }
  const auto cold_end{std::chrono::high_resolution_clock::now()};
  const auto cold_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      cold_end - cold_start)};

  const auto iterations = 1 + ((MAX_WARMUP_TIME - 1) / cold_duration.count());
  for (int i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++) {
    validate_all(validator, schema, instances);
  }

  const auto warm_start{std::chrono::high_resolution_clock::now()};
  validate_all(validator, schema, instances);
  const auto warm_end{std::chrono::high_resolution_clock::now()};
  const auto warm_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      warm_end - warm_start)};

  std::cout << cold_duration.count() << "," << warm_duration.count() << "," << compile_duration.count() << "," << parse_duration.count() << "\n";

  return EXIT_SUCCESS;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "Usage: " << argv[0] << " <schema>\n";
    return EXIT_FAILURE;
  }

  try {
    const std::filesystem::path example{argv[1]};
    return validate(example);
  } catch (const std::exception &e) {
    std::cerr << "Error during valijson benchmark: " << e.what() << "\n";
    return EXIT_FAILURE;
  }
}
