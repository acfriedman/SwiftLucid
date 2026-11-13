# Installation

SwiftLucid needs **macOS 14+** and a **Swift 6** toolchain (Xcode 16 or later), and **git** for
`--staged` and `--since`. Install it once for yourself with Mint, or pin a version in your repository so
everyone on a team runs the same one.

## Mint

```bash
mint install acfriedman/SwiftLucid
```

[Mint](https://github.com/yonaskolb/Mint) builds the tag you name, or the latest, and links `swiftlucid`
into `~/.mint/bin`, which needs to be on your `PATH`. To pin one version for a team, add a `Mintfile` at
the repository's root holding the line `acfriedman/SwiftLucid@0.2.0`, and run it with
`mint run swiftlucid`.

## Swift Package Manager

For a version pinned in the repository with nothing to install, keep a small package beside the project,
`BuildTools/Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/acfriedman/SwiftLucid", exact: "0.2.0")
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
```

Add an empty `BuildTools/Empty.swift` for the target, commit both, and ignore `BuildTools/.build` and
`BuildTools/.swiftpm`. Then this runs the pinned version:

```bash
swift run -c release --package-path BuildTools swiftlucid
```

It is built once and kept until the pin changes; the first build takes a few minutes. SwiftLucid never
reads a package manifest, so `BuildTools/Package.swift` owes no docs.

## From source

```bash
git clone https://github.com/acfriedman/SwiftLucid && cd SwiftLucid
swift build -c release
.build/release/swiftlucid path/to/YourProject/Sources
```

Build for release: a debug build is several times slower on a large codebase.

## Next

[Setup](Setup.md) runs SwiftLucid from a commit hook, Xcode, or CI, with whichever install you chose.
