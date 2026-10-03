// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "corvus-swift-benchmark",
    dependencies: [
        // The latest release (the Dockerfile resolves it afresh on every build).
        .package(url: "https://github.com/corvus-dotnet/corvus-json-schema-swift", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "corvus_swift_benchmark",
            dependencies: [.product(name: "CorvusJsonSchema", package: "corvus-json-schema-swift")]
        ),
    ]
)
