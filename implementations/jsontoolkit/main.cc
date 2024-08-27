#include <sourcemeta/jsontoolkit/json.h>
#include <sourcemeta/jsontoolkit/jsonschema.h>

#include <chrono>
#include <iostream>
#include <filesystem>

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "Usage: " << argv[0] << " <schema>\n";
    return EXIT_FAILURE;
  }

  const std::filesystem::path example{argv[1]};
  const auto schema{sourcemeta::jsontoolkit::from_file(example / "schema.json")};
  const auto instance{sourcemeta::jsontoolkit::from_file(example / "instance.json")};

  const auto schema_template{sourcemeta::jsontoolkit::compile(
      schema, sourcemeta::jsontoolkit::default_schema_walker,
      sourcemeta::jsontoolkit::official_resolver,
      sourcemeta::jsontoolkit::default_schema_compiler)};

  const auto timestamp_start{std::chrono::high_resolution_clock::now()};
  const auto result{sourcemeta::jsontoolkit::evaluate(
    schema_template, instance)};
  const auto timestamp_end{std::chrono::high_resolution_clock::now()};
  if (!result) {
    return EXIT_FAILURE;
  }

  const auto duration{
    std::chrono::duration_cast<std::chrono::nanoseconds>(timestamp_end - timestamp_start)};
  std::cout << duration.count() << "\n";

  return EXIT_SUCCESS;
}
