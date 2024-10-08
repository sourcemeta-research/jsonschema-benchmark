#include <jsoncons/json.hpp>
#include <jsoncons_ext/jsonschema/jsonschema.hpp>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

using jsoncons::json;
namespace jsonschema = jsoncons::jsonschema;

int validate(const std::filesystem::path &example) {
  std::ifstream input_schema((example / "schema.json").string());
  const auto schema = json::parse(input_schema);
  const auto compiled = jsonschema::make_json_schema(schema);

  std::ifstream input_instances((example / "instances.jsonl").string());
  std::vector<json> instances;
  std::string line;
  while (std::getline(input_instances, line)) {
    const auto instance = json::parse(line);
    instances.push_back(instance);
  }

  const auto timestamp_start{std::chrono::high_resolution_clock::now()};

  for (const auto &instance : instances) {
    compiled.validate(instance);
  }

  const auto timestamp_end{std::chrono::high_resolution_clock::now()};
  const auto duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      timestamp_end - timestamp_start)};
  std::cout << duration.count() << "\n";

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
    std::cerr << "Error during jsoncons benchmark: " << e.what() << "\n";
    return EXIT_FAILURE;
  }
}
