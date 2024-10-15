#include <sourcemeta/jsontoolkit/json.h>
#include <sourcemeta/jsontoolkit/jsonl.h>
#include <sourcemeta/jsontoolkit/jsonschema.h>

#include <sourcemeta/blaze/compiler.h>
#include <sourcemeta/blaze/evaluator.h>

#include <chrono>
#include <filesystem>
#include <iostream>
#include <vector>

int validate(const std::filesystem::path &example) {
  const auto schema{
      sourcemeta::jsontoolkit::from_file(example / "schema.json")};
  auto stream{sourcemeta::jsontoolkit::read_file(example / "instances.jsonl")};
  std::vector<sourcemeta::jsontoolkit::JSON> instances;
  for (const auto &instance : sourcemeta::jsontoolkit::JSONL{stream}) {
    instances.push_back(instance);
  }

  const auto schema_template{sourcemeta::blaze::compile(
      schema, sourcemeta::jsontoolkit::default_schema_walker,
      sourcemeta::jsontoolkit::official_resolver,
      sourcemeta::blaze::default_schema_compiler,
      sourcemeta::blaze::Mode::FastValidation)};

  sourcemeta::blaze::EvaluationContext context;
  const auto timestamp_start{std::chrono::high_resolution_clock::now()};

  auto num = 0;
  for (const auto &instance : instances) {
    context.prepare(instance);
    num += 1;
    const auto result{
        sourcemeta::blaze::evaluate(schema_template, context)};
    if (!result) {
      std::cerr << "Error validating instance " << num << "\n";
      return EXIT_FAILURE;
    }
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
    std::cerr << "Error during Blaze benchmark: " << e.what() << "\n";
    return EXIT_FAILURE;
  }
}
