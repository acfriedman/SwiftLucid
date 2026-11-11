import LucidRead
import LucidLint
import Foundation

/// Command-line entry: `swiftlucid [--include-tests] [--summary] [--style <file>] [--staged | --since <revision>] <path>...`
/// lints every path, `--staged` and `--since` judging only the declarations a change added or changed.
///
/// Paths may be files or directories; directories are walked for `.swift` files, skipping hidden folders,
/// the folders dependency managers check code out into, and, unless `--include-tests` is given, any
/// directory whose name ends in `Tests`. The lint follows the project's house style: the file `--style`
/// names, else the nearest `.swiftlucid.json` in the current directory or above it, else SwiftLucid's own.
let arguments = Array(CommandLine.arguments.dropFirst())
let includeTests = arguments.contains("--include-tests")
let summaryOnly = arguments.contains("--summary")
let staged = arguments.contains("--staged")
let usage = "usage: swiftlucid [--include-tests] [--summary] [--style <file>] [--staged | --since <revision>] <path>...\n"
var options: [String: String] = [:]
var paths: [String] = []
var index = 0
while index < arguments.count {
    let argument = arguments[index]
    index += 1
    if argument == "--help" || argument == "-h" {
        print(usage, terminator: "")
        exit(0)
    }
    guard argument.hasPrefix("--") else { paths.append(argument); continue }
    if ["--style", "--since"].contains(argument) {
        guard index < arguments.count else {
            FileHandle.standardError.write(Data("swiftlucid: \(argument) needs a value\n".utf8))
            exit(64)
        }
        options[argument] = arguments[index]
        index += 1
    } else if !["--include-tests", "--summary", "--staged"].contains(argument) {
        FileHandle.standardError.write(Data(("swiftlucid: unknown option \(argument)\n" + usage).utf8))
        exit(64)
    }
}

guard !paths.isEmpty else {
    FileHandle.standardError.write(Data(usage.utf8))
    exit(64)
}

/// The project's house style, which a broken file stops the run over rather than linting by another.
let style: HouseStyle = {
    do {
        return try options["--style"].map { try HouseStyle.load($0) } ?? HouseStyle.find(from: FileManager.default.currentDirectoryPath)
    } catch {
        FileHandle.standardError.write(Data("swiftlucid: \(error)\n".utf8))
        exit(65)
    }
}()

/// Collects the `.swift` files under a path, and the Objective-C headers whose types their docs may link.
/// A path that does not exist exits with status 66, so a typo cannot pass as a clean run.
///
/// - Parameter path: A file or directory, as given on the command line.
/// - Returns: The files, sorted, so output order is stable across runs; empty for a file SwiftLucid does
///   not read.
func sourceFiles(under path: String) -> [String] {
    do {
        return try SourceFiles.files(under: path, includeTests: includeTests, extensions: SourceFiles.readExtensions)
    } catch {
        FileHandle.standardError.write(Data("swiftlucid: no such path: \(path)\n".utf8))
        exit(66)
    }
}

let sources = Timing.measure("read files") {
    paths.flatMap(sourceFiles(under:)).compactMap { file -> (file: String, source: String)? in
        (try? String(contentsOfFile: file, encoding: .utf8)).map { (file, $0) }
    }
}

// A change's lint judges only what it touched; without one, the whole of every path is judged.
let changed: ChangeLint.Result?
if staged || options["--since"] != nil {
    do {
        changed = try ChangeLint.run(paths: paths, since: options["--since"], workingTree: sources, style: style, includeTests: includeTests)
    } catch {
        // What git said reads better than the error's own description.
        FileHandle.standardError.write(Data("swiftlucid: \((error as? Revision.Failure)?.message ?? "\(error)")\n".utf8))
        exit(65)
    }
} else {
    changed = nil
}
let diagnostics = changed?.diagnostics ?? Linter.check(sources: sources, style: style)

if !summaryOnly {
    for diagnostic in diagnostics { print(diagnostic.rendered) }
}
let byRule = Dictionary(grouping: diagnostics, by: \.rule).mapValues(\.count)
let errors = diagnostics.filter { $0.severity == .error }.count
// Headers and module pages are read for their names and prose, so the files counted are the Swift ones.
let swiftCount = sources.filter { $0.file.hasSuffix(".swift") }.count
let warnings = diagnostics.count - errors
let judged = changed.map { "\($0.declarations) changed declaration\($0.declarations == 1 ? "" : "s")" }
    ?? "\(swiftCount) file\(swiftCount == 1 ? "" : "s")"
var summary = "\(errors) error\(errors == 1 ? "" : "s")" + (warnings > 0 ? " and \(warnings) warning\(warnings == 1 ? "" : "s")" : "")
    + " in " + judged
if !byRule.isEmpty {
    summary += "\n" + byRule.sorted { $0.value > $1.value }.map { "  \($0.value)\t\($0.key.rawValue)" }.joined(separator: "\n")
}
FileHandle.standardError.write(Data((summary + "\n").utf8))
// Only errors fail the run, so a style can bring a rule in as a warning before it gates anything.
exit(errors == 0 ? 0 : 1)
