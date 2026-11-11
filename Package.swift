// swift-tools-version: 6.0
import PackageDescription

// Two layers and a command, each depending only on the ones before it, so the compiler keeps them apart:
// LucidRead parses the sources once, into declarations and their doc comments; LucidLint checks those
// docs against a project's house style; swiftlucid runs the lint from a terminal, a commit hook, or CI.
let package = Package(
    name: "SwiftLucid",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "swiftlucid", targets: ["swiftlucid"]),
        .library(name: "LucidRead", targets: ["LucidRead"]),
        .library(name: "LucidLint", targets: ["LucidLint"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "603.0.1")
    ],
    targets: [
        // Each module's README is its page, which the lint reads and the build leaves out.
        .target(name: "LucidRead", dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax")
        ], exclude: ["README.md"]),
        .target(name: "LucidLint", dependencies: ["LucidRead"], exclude: ["README.md"]),
        .executableTarget(name: "swiftlucid", dependencies: ["LucidRead", "LucidLint"], exclude: ["README.md"]),
        .testTarget(name: "LucidTests", dependencies: ["LucidRead", "LucidLint"])
    ]
)
