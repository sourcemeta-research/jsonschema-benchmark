// The jsonschema-benchmark entry point for valijson (draft 4 and 7), through its RapidJSON adapter, mirroring
// implementations/blaze/main.cc: read the instances into memory, parse each into a RapidJSON document (timed),
// compile (timed), validate every document once cold, warm up, validate once more warm. Prints
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
#include <algorithm>
#include <chrono>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "rapidjson/document.h"
#include "valijson/adapters/rapidjson_adapter.hpp"
#include "valijson/schema.hpp"
#include "valijson/schema_parser.hpp"
#include "valijson/validator.hpp"

using clock_type = std::chrono::high_resolution_clock;
using valijson::SchemaParser;
using valijson::adapters::RapidJsonAdapter;

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

static bool validate_all(valijson::Validator& validator, const valijson::Schema& schema,
                         const std::vector<std::unique_ptr<rapidjson::Document>>& instances, bool report) {
    bool valid = true;
    for (std::size_t i = 0; i < instances.size(); i++) {
        RapidJsonAdapter adapter(*instances[i]);
        if (!validator.validate(schema, adapter, nullptr)) {
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
    try {
        std::string schema_text = read_file(argv[1]);
        std::string contents = read_file(argv[2]);
        std::vector<std::string> lines;
        std::istringstream stream(contents);
        for (std::string line; std::getline(stream, line);) {
            if (!line.empty()) lines.push_back(line);
        }

        auto parse_start = clock_type::now();
        std::vector<std::unique_ptr<rapidjson::Document>> instances;
        instances.reserve(lines.size());
        for (const auto& line : lines) {
            auto document = std::make_unique<rapidjson::Document>();
            document->Parse(line.c_str(), line.size());
            if (document->HasParseError()) throw std::runtime_error("an instance is not JSON");
            instances.push_back(std::move(document));
        }
        auto parse_end = clock_type::now();

        rapidjson::Document schema_document;
        schema_document.Parse(schema_text.c_str(), schema_text.size());
        if (schema_document.HasParseError()) throw std::runtime_error("the schema is not JSON");
        std::string dialect = schema_document.HasMember("$schema") && schema_document["$schema"].IsString()
                                  ? schema_document["$schema"].GetString()
                                  : "";

        auto compile_start = clock_type::now();
        valijson::Schema schema;
        SchemaParser parser(dialect.rfind("http://json-schema.org/draft-04/schema", 0) == 0 ? SchemaParser::kDraft4
                                                                                             : SchemaParser::kDraft7);
        RapidJsonAdapter schema_adapter(schema_document);
        parser.populateSchema(schema_adapter, schema);
        // Strong type checking (a JSON number is never a string), as JSON Schema defines.
        valijson::Validator validator(valijson::Validator::kStrongTypes);
        auto compile_end = clock_type::now();

        auto cold_start = clock_type::now();
        bool valid = validate_all(validator, schema, instances, true);
        auto cold_end = clock_type::now();

        long long cold = ns(cold_start, cold_end);
        long long iterations = 1 + (MAX_WARMUP_TIME - 1) / std::max(cold, 1LL);
        for (long long i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++)
            validate_all(validator, schema, instances, false);

        auto warm_start = clock_type::now();
        validate_all(validator, schema, instances, false);
        auto warm_end = clock_type::now();

        std::cout << cold << "," << ns(warm_start, warm_end) << "," << ns(compile_start, compile_end) << ","
                  << ns(parse_start, parse_end) << "\n";
        return valid ? 0 : 1;
    } catch (const std::exception& e) {
        std::cerr << "Error during valijson benchmark: " << e.what() << "\n";
        return 1;
    }
}
