#include <jsoncons/json.hpp>
#include <jsoncons_ext/jsonschema/jsonschema.hpp>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

#define WARMUP_ITERATIONS 100L
#define MAX_WARMUP_TIME 10000000000

using jsoncons::json;
namespace jsonschema = jsoncons::jsonschema;

template <typename Json>
void validate_all(const jsonschema::json_schema<Json> &compiled, const std::vector<json> &instances) {
  for (const auto &instance : instances) {
    compiled.validate(instance);
  }
}

int validate(const std::filesystem::path &example) {
  std::ifstream input_schema((example / "schema-noformat.json").string());
  const auto schema = json::parse(input_schema);

  const auto compile_start{std::chrono::high_resolution_clock::now()};
  const auto compiled = jsonschema::make_json_schema(schema);
  const auto compile_end{std::chrono::high_resolution_clock::now()};
  const auto compile_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      compile_end - compile_start)};

  std::ifstream input_instances((example / "instances.jsonl").string());
  std::vector<json> instances;
  std::string line;
  while (std::getline(input_instances, line)) {
    const auto instance = json::parse(line);
    instances.push_back(instance);
  }

  const auto cold_start{std::chrono::high_resolution_clock::now()};
  validate_all(compiled, instances);
  const auto cold_end{std::chrono::high_resolution_clock::now()};
  const auto cold_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      cold_end - cold_start)};

  const auto iterations = 1 + ((MAX_WARMUP_TIME - 1) / cold_duration.count());
  for (int i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++) {
    validate_all(compiled, instances);
  }

  const auto warm_start{std::chrono::high_resolution_clock::now()};
  validate_all(compiled, instances);
  const auto warm_end{std::chrono::high_resolution_clock::now()};
  const auto warm_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      warm_end - warm_start)};

  std::cout << cold_duration.count() << "," << warm_duration.count() << "," << compile_duration.count() << "\n";

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
