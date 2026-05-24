#include <rapidjson/document.h>
#include <rapidjson/error/en.h>
#include <rapidjson/schema.h>

#include <filesystem>
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <vector>
#include <chrono>
#include <iostream>

namespace fs = std::filesystem;

#define WARMUP_ITERATIONS 100L
#define MAX_WARMUP_TIME 10000000000

bool validate_all(const auto &instances, const auto &schema_template) {
    for (std::size_t num = 0; num < instances.size(); num++) {
        const std::string json = instances[num];
        rapidjson::SchemaValidator validator(schema_template);
        rapidjson::GenericReader<rapidjson::UTF8<>, rapidjson::UTF8<>> reader;
        rapidjson::StringStream is(json.c_str());
        reader.Parse(is, validator);
        if (!validator.IsValid()) {
            std::cerr << "Error validating instance " << num << "\n";
            return false;
        }
  }

  return true;
}

std::string read_file(const fs::path &path) {
  std::ifstream f(path, std::ios::binary);
  if (!f) {
    throw std::runtime_error(std::format("Cannot open file: {}", path.string()));
  }
  return {std::istreambuf_iterator<char>{f}, {}};
}

int validate(const std::filesystem::path &example) {
  std::cerr << std::format("benchmarking schema in folder: {}\n", example.string());
  const std::string instances_text = read_file(example / "instances.jsonl");

  std::vector<std::string> instances;
   std::stringstream instances_stream(instances_text);
   std::string line;

    while (getline(instances_stream, line)) {
        instances.push_back(line);
    }

  const std::string schema_text = read_file(example / "schema.json");

  const auto compile_start{std::chrono::high_resolution_clock::now()};
  rapidjson::Document json_schema_source;
  if (json_schema_source.Parse(schema_text.c_str(), schema_text.size()).HasParseError()) {
    throw std::runtime_error(
        std::format("Schema parser error at offset {}: {}", json_schema_source.GetErrorOffset(),
                    rapidjson::GetParseError_En(json_schema_source.GetParseError())));
  }
  rapidjson::SchemaDocument rapidjson_schema(json_schema_source);

  const auto compile_end{std::chrono::high_resolution_clock::now()};
  const auto compile_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      compile_end - compile_start)};

  const auto cold_start{std::chrono::high_resolution_clock::now()};
  if (!validate_all(instances, rapidjson_schema)) {
    return EXIT_FAILURE;
  }
  const auto cold_end{std::chrono::high_resolution_clock::now()};
  const auto cold_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      cold_end - cold_start)};

  const auto iterations = 1 + ((MAX_WARMUP_TIME - 1) / cold_duration.count());
  for (int i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++) {
    validate_all(instances, rapidjson_schema);
  }

  const auto warm_start{std::chrono::high_resolution_clock::now()};
  validate_all(instances, rapidjson_schema);
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
    std::cerr << "Error during Blaze benchmark: " << e.what() << "\n";
    return EXIT_FAILURE;
  }
}
