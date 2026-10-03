// The jsonschema-benchmark entry point for Corvus.JsonSchema's C library (corvus-json-schema), through its C++
// wrapper, mirroring implementations/blaze/main.cc: read the instances into memory, parse each into a document
// (timed), compile (timed), validate every document once cold, warm up, validate once more warm. Prints
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "corvus_json_schema.hpp"

namespace cjs = corvus::json_schema;
using clock_type = std::chrono::high_resolution_clock;

static constexpr long long WARMUP_ITERATIONS = 100;
static constexpr long long MAX_WARMUP_TIME = 10000000000LL;

static std::string read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    std::ostringstream s;
    s << in.rdbuf();
    return s.str();
}

static bool validate_all(const cjs::validator& v, const std::vector<cjs::document>& instances) {
    bool valid = true;
    for (std::size_t i = 0; i < instances.size(); i++) {
        if (!v.is_valid(instances[i])) {
            std::cerr << "Error validating instance " << i << "\n";
            valid = false;
        }
    }
    return valid;
}

static long long ns(clock_type::time_point a, clock_type::time_point b) {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(b - a).count();
}

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <schema.json> <instances.jsonl>\n";
        return 1;
    }
    try {
        std::string schema = read_file(argv[1]);
        std::string contents = read_file(argv[2]);
        std::vector<std::string_view> lines;
        std::size_t start = 0;
        while (start < contents.size()) {
            std::size_t end = contents.find('\n', start);
            if (end == std::string::npos) end = contents.size();
            if (end > start) lines.emplace_back(contents.data() + start, end - start);
            start = end + 1;
        }

        auto parse_start = clock_type::now();
        std::vector<cjs::document> instances;
        instances.reserve(lines.size());
        for (auto line : lines) instances.push_back(cjs::document::parse_borrowed(line));
        auto parse_end = clock_type::now();

        auto compile_start = clock_type::now();
        auto v = cjs::validator::compile(schema);
        auto compile_end = clock_type::now();

        auto cold_start = clock_type::now();
        bool valid = validate_all(v, instances);
        auto cold_end = clock_type::now();

        long long cold = ns(cold_start, cold_end);
        long long iterations = 1 + (MAX_WARMUP_TIME - 1) / std::max(cold, 1LL);
        for (long long i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++) validate_all(v, instances);

        auto warm_start = clock_type::now();
        validate_all(v, instances);
        auto warm_end = clock_type::now();

        std::cout << cold << "," << ns(warm_start, warm_end) << "," << ns(compile_start, compile_end) << ","
                  << ns(parse_start, parse_end) << "\n";
        return valid ? 0 : 1;
    } catch (const std::exception& e) {
        std::cerr << "Error during Corvus benchmark: " << e.what() << "\n";
        return 1;
    }
}
