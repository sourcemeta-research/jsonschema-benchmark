// The jsonschema-benchmark entry point for Corvus.JsonSchema's Swift package (CorvusJsonSchema), over its C library.
//
//   corvus_swift_benchmark <schema.json> <instances.jsonl>
//
// Mirrors the other implementations: read the instance file, parse every instance into a document (timed), compile
// the schema (timed), validate every instance once cold, warm up, validate once more warm. Prints one line
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
import CorvusJsonSchema
import Foundation

let warmupIterations: UInt64 = 100
let maxWarmupTime: UInt64 = 10_000_000_000  // 10 seconds

func now() -> UInt64 {
    DispatchTime.now().uptimeNanoseconds
}

func validateAll(_ validator: Validator, _ instances: [Document]) throws -> Bool {
    var valid = true
    for instance in instances where try !validator.isValid(instance) {
        valid = false
    }
    return valid
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write("Usage: corvus_swift_benchmark <schema> <instances>\n".data(using: .utf8)!)
    exit(1)
}

do {
    let schema = try String(contentsOfFile: arguments[1], encoding: .utf8)
    let lines = try String(contentsOfFile: arguments[2], encoding: .utf8)
        .split(separator: "\n", omittingEmptySubsequences: true)
        .map(String.init)

    let parseStart = now()
    let instances = try lines.map { try Document(json: $0) }
    let parse = now() - parseStart

    let compileStart = now()
    let validator = try Validator(schema: schema)
    let compile = now() - compileStart

    let coldStart = now()
    let valid = try validateAll(validator, instances)
    let cold = now() - coldStart

    let iterations = (maxWarmupTime + max(cold, 1) - 1) / max(cold, 1)
    for _ in 0..<min(iterations, warmupIterations) {
        _ = try validateAll(validator, instances)
    }

    let warmStart = now()
    _ = try validateAll(validator, instances)
    let warm = now() - warmStart

    print("\(cold),\(warm),\(compile),\(parse)")
    exit(valid ? 0 : 1)
} catch {
    FileHandle.standardError.write("Error during Corvus benchmark: \(error)\n".data(using: .utf8)!)
    exit(1)
}
