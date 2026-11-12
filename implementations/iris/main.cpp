// The jsonschema-benchmark entry point for IRIS (2020-12), mirroring implementations/blaze/main.cc: read the
// instances into memory, compile (timed), validate every instance once cold, warm up, validate once more warm.
// Prints "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
//
// IRIS validates JSON text, parsing it as it goes, and has no separately parsed document to validate. So its cold
// and warm figures include parsing, and its parse figure is only taking a copy of each line.
#include <algorithm>
#include <chrono>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "iris/validator.hpp"

using clock_type = std::chrono::high_resolution_clock;

static constexpr long long WARMUP_ITERATIONS = 100;
static constexpr long long MAX_WARMUP_TIME = 10000000000LL;

static std::string read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    std::ostringstream s;
    s << in.rdbuf();
    return s.str();
}

static long long ns(clock_type::time_point a, clock_type::time_point b) {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(b - a).count();
}

static bool validate_all(const iris::Validator& validator, const std::vector<std::string>& instances, bool report) {
    bool valid = true;
    for (std::size_t i = 0; i < instances.size(); i++) {
        if (!validator.validate(instances[i]).ok()) {
            if (report) std::cerr << "Error validating instance " << i << "\n";
            valid = false;
        }
    }
    return valid;
}

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <schema.json> <instances.jsonl>\n";
        return 1;
    }
    std::string schema = read_file(argv[1]);
    std::string contents = read_file(argv[2]);

    auto parse_start = clock_type::now();
    std::vector<std::string> instances;
    std::istringstream stream(contents);
    for (std::string line; std::getline(stream, line);) {
        if (!line.empty()) instances.push_back(line);
    }
    auto parse_end = clock_type::now();

    auto compile_start = clock_type::now();
    iris::ValidatorBuild build;
    iris::Validator validator = iris::Validator::from_schema_json(schema, build);
    auto compile_end = clock_type::now();
    if (!build.ok) {
        std::cerr << "Error compiling the schema: " << build.diagnostic << "\n";
        return 1;
    }

    auto cold_start = clock_type::now();
    bool valid = validate_all(validator, instances, true);
    auto cold_end = clock_type::now();

    long long cold = ns(cold_start, cold_end);
    long long iterations = 1 + (MAX_WARMUP_TIME - 1) / std::max(cold, 1LL);
    for (long long i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++) validate_all(validator, instances, false);

    auto warm_start = clock_type::now();
    validate_all(validator, instances, false);
    auto warm_end = clock_type::now();

    std::cout << cold << "," << ns(warm_start, warm_end) << "," << ns(compile_start, compile_end) << ","
              << ns(parse_start, parse_end) << "\n";
    return valid ? 0 : 1;
}
