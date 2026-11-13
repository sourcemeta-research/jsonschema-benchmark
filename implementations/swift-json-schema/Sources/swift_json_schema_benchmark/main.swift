// The jsonschema-benchmark entry point for swift-json-schema (2020-12).
//
//   swift_json_schema_benchmark <schema.json> <instances.jsonl>
//
// Mirrors the other implementations: read the instance file, parse every instance into a JSONValue (timed), compile
// the schema (timed), validate every instance once cold, warm up, validate once more warm. Prints one line
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
import Foundation
import JSONSchema

let warmupIterations: UInt64 = 100
let maxWarmupTime: UInt64 = 10_000_000_000  // 10 seconds

func now() -> UInt64 {
    DispatchTime.now().uptimeNanoseconds
}

func validateAll(_ schema: Schema, _ instances: [JSONValue]) -> Bool {
    var valid = true
    for instance in instances where !schema.validate(instance).isValid {
        valid = false
    }
    return valid
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write("Usage: swift_json_schema_benchmark <schema> <instances>\n".data(using: .utf8)!)
    exit(1)
}

do {
    let decoder = JSONDecoder()
    let rawSchema = try decoder.decode(JSONValue.self, from: Data(contentsOf: URL(fileURLWithPath: arguments[1])))
    let lines = try String(contentsOfFile: arguments[2], encoding: .utf8)
        .split(separator: "\n", omittingEmptySubsequences: true)
        .map { Data($0.utf8) }

    let parseStart = now()
    let instances = try lines.map { try decoder.decode(JSONValue.self, from: $0) }
    let parse = now() - parseStart

    let compileStart = now()
    let schema = try Schema(rawSchema: rawSchema, context: .init(dialect: .draft2020_12))
    let compile = now() - compileStart

    let coldStart = now()
    let valid = validateAll(schema, instances)
    let cold = now() - coldStart

    let iterations = (maxWarmupTime + max(cold, 1) - 1) / max(cold, 1)
    for _ in 0..<min(iterations, warmupIterations) {
        _ = validateAll(schema, instances)
    }

    let warmStart = now()
    _ = validateAll(schema, instances)
    let warm = now() - warmStart

    print("\(cold),\(warm),\(compile),\(parse)")
    exit(valid ? 0 : 1)
} catch {
    FileHandle.standardError.write("Error during swift-json-schema benchmark: \(error)\n".data(using: .utf8)!)
    exit(1)
}
