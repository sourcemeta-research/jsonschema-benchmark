// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-json-schema-benchmark",
    dependencies: [
        // The latest release (the Dockerfile resolves it afresh on every build).
        .package(url: "https://github.com/ajevans99/swift-json-schema.git", from: "0.13.0"),
    ],
    targets: [
        .executableTarget(
            name: "swift_json_schema_benchmark",
            dependencies: [.product(name: "JSONSchema", package: "swift-json-schema")]
        ),
    ]
)
