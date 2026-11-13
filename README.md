# SwiftLucid

A doc-comment linter for Swift: every declaration explains itself, in the shape Swift's own doc format
and DocC expect.

## How it works

SwiftLucid parses every file once with swift-syntax and checks each `///` comment against one shape: a
one- or two-sentence summary (what, then why), a blank line, then a markup block for every parameter, the
return value, and what it throws. Links like ``` ``Cart/total()`` ``` must name something the sources
declare, and each module's `README.md` page must list its public types. A project chooses how strict to
be in `.swiftlucid.json`, and a commit hook can judge only what a change touched.

## Requirements

- **macOS 14+** and a **Swift 6** toolchain (Xcode 16 or later).
- **git**, for `--staged` and `--since`.

## Installation

### Mint

```bash
mint install acfriedman/SwiftLucid
```

[Mint](https://github.com/yonaskolb/Mint) builds the tag you name, or the latest, and links `swiftlucid`
into `~/.mint/bin`. A team pins one version in a `Mintfile` at the repository's root, holding the line
`acfriedman/SwiftLucid@0.2.0`, and runs it with `mint run swiftlucid`.

### Swift Package Manager

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
`BuildTools/.swiftpm`. Then `swift run -c release --package-path BuildTools swiftlucid` runs the pinned
version, built once and kept until the pin changes; the first build takes a few minutes.

### From source

```bash
git clone https://github.com/acfriedman/SwiftLucid && cd SwiftLucid
swift build -c release
.build/release/swiftlucid path/to/YourProject/Sources
```

Build for release: a debug build is several times slower on a large codebase.

## Usage

| Command | Does |
| --- | --- |
| `swiftlucid <paths>` | lints; `--include-tests` reads `*Tests` folders too, `--summary` prints only counts by rule, `--style <file>` reads a house style other than the nearest |
| `swiftlucid --staged <paths>` | lints only the declarations the next commit adds or changes, for a pre-commit hook |
| `swiftlucid --since <rev> <paths>` | lints only the declarations changed since a revision, for a build phase or a pull request's check |
| `swiftlucid --version` | prints the version |

Each finding is one line in compiler format, so Xcode shows it beside the code, and the exit status is 1
when any is an error, so the same command gates a commit or a build. A folder is walked for `.swift`
files, and for `.h` files whose Objective-C types the docs may link, skipping hidden folders and those
dependency managers fill: `SourcePackages`, `DerivedData`, `Pods`, and `Carthage`.

## Setup

A codebase that predates its house style has findings nobody will fix at once, so SwiftLucid's hooks
judge a change rather than the whole codebase. `--staged` and `--since` read the whole project, so links
into untouched files resolve, but report only the declarations the change added or changed, a body edit
included; code that only moved touches nothing.

### Git pre-commit hook

```bash
#!/bin/sh
# .git/hooks/pre-commit: lint the doc comments this commit adds or changes
export PATH="$HOME/.mint/bin:$PATH"   # Git apps run hooks without your shell's PATH
if command -v swiftlucid >/dev/null 2>&1; then
  exec swiftlucid --staged .
fi
echo "warning: swiftlucid is not installed, so this commit's docs were not linted" >&2
```

Save it as `.git/hooks/pre-commit` and `chmod +x` it. A team commits it as `.githooks/pre-commit`
instead, and each clone runs `git config core.hooksPath .githooks` once. For the version pinned in
`BuildTools`, use `exec swift run --quiet -c release --package-path BuildTools swiftlucid --staged .`, or
`exec mint run swiftlucid --staged .` with a `Mintfile`. `git commit --no-verify` skips the hook.

With the [pre-commit](https://pre-commit.com) framework, add SwiftLucid to `.pre-commit-config.yaml`; it
builds the tagged version itself:

```yaml
repos:
  - repo: https://github.com/acfriedman/SwiftLucid
    rev: 0.2.0
    hooks:
      - id: swiftlucid
```

### Xcode build phase

Add a Run Script phase after Compile Sources, so Xcode shows findings on what you have changed since the
last commit as you build:

```bash
cd "$SRCROOT"
SDKROOT=$(xcrun --sdk macosx --show-sdk-path) \
  swift run --quiet -c release --package-path BuildTools swiftlucid --since HEAD "$SRCROOT"
```

`SDKROOT` builds the tool for the Mac even in an iOS target. With a local install instead:

```bash
cd "$SRCROOT"
export PATH="$HOME/.mint/bin:$PATH"
if command -v swiftlucid >/dev/null 2>&1; then
  swiftlucid --since HEAD "$SRCROOT"
else
  echo "warning: swiftlucid is not installed; see https://github.com/acfriedman/SwiftLucid#installation"
fi
```

- **Xcode 15 and later** sandbox scripts, which stops SwiftLucid reading the sources and git. Set
  **User Script Sandboxing** (`ENABLE_USER_SCRIPT_SANDBOXING`) to **No** for the target.
- Uncheck **Based on dependency analysis**, so the phase runs on every build.
- An error fails the build. While a team brings the style in, `"severity": "warning"` in
  `.swiftlucid.json` shows findings without failing anything.
- To show every finding rather than a change's, drop `--since HEAD`.

### CI

`swiftlucid --since origin/main .` judges a branch the same way, after a checkout that fetches the
history back to the base, such as `fetch-depth: 0` in GitHub Actions.

## Rules

| Code | Fires when |
| --- | --- |
| `missing-doc` | a non-private declaration has no `///` comment; the house style can ask only from `public` |
| `block-doc` | the comment is `/** */`; what it says is still checked |
| `summary-empty`, `summary-sentences`, `summary-terminator`, `summary-capital`, `summary-opener` | the summary is missing, isn't one or two sentences, has no period, starts lowercase, or opens with "This method…" |
| `markup-order`, `markup-spacing`, `markup-case`, `markup-unknown` | a callout follows prose, touches the summary, is lowercase, or is a near miss like `- Return:` |
| `parameter-missing`, `parameter-unknown`, `parameter-empty`, `parameter-form`, `parameter-order`, `parameter-duplicate` | a parameter entry is missing, extra, empty, mixes forms, is out of order, or repeats |
| `returns-*`, `throws-*` | `- Returns:` or `- Throws:` is missing, unexpected, or empty |
| `symbol-link` | a single-backticked `Type.member` should be a ``` ``Type/member`` ``` link |
| `dead-link` | a ``` ``Symbol`` ``` link names nothing the sources declare; a link into a module some file imports, as in ``` ``Alamofire/Session`` ```, or to a type an Objective-C header declares, is taken on trust |
| `exempt-reason`, `exempt-documented` | a `// swiftlucid:exempt` marker has no reason, or sits beside a doc |
| `module-doc-missing`, `module-doc-title` | a module under `Sources` has no `README.md` page, or its page's `# Title` names another module |
| `module-doc-unlisted`, `module-doc-length` | a public type is linked nowhere on its module's page, or the page's Overview runs past five sentences, or a Topics group's lead past one |

Types, properties, and enum cases get only the summary rules. Code fences in a comment are quoted, not
checked.

## Module pages

Each module under `Sources` keeps a `README.md` that says what it does and groups its types, short enough
to read at a glance, and the lint keeps it in step with the code:

```markdown
# LucidRead

Parses the sources once into declarations and their doc comments.

## Overview

Every other module starts from a ``Reading``. (Five sentences at most.)

## Topics

### Reading the sources

- ``Reading``
- ``DeclarationReader``
```

The summary answers to the same rules as a doc's, a link must name something, and every public type
must be linked somewhere on the page. SwiftPM wants each target to leave the file out of the build:
`exclude: ["README.md"]`.

## Exemptions

A protocol requirement inherits the protocol's doc, so SwiftLucid skips:
- **known requirements** by signature, such as `hash(into:)`, `init(from:)`, `body`, and `description`;
- **members of a conformance extension** (`extension T: P`), for `missing-doc` only;
- **memberwise initializers**, whose body only assigns their parameters;
- **anything marked** `// swiftlucid:exempt <reason>` on the line above.

## House style

The rules above are SwiftLucid's own house style. A project picks its own in `.swiftlucid.json`, which
SwiftLucid reads from the current directory or the nearest folder above it. Every key is optional:

```json
{
  "severity": "warning",
  "rules": { "missing-doc": "error", "summary-*": "off" },
  "exclude": ["Sources/Generated", "**/*.pb.swift"],
  "requireDocs": "public"
}
```

| Key | Does |
| --- | --- |
| `severity` | the level of every rule `rules` doesn't name: `error` (the default), `warning`, or `off` |
| `rules` | a level per rule code, or per prefix ending in `*`; a code wins over a prefix |
| `exclude` | paths not linted, from the folder holding `.swiftlucid.json`: `*`, `**`, `?`, or a folder for all of it; their declarations still resolve links |
| `requireDocs` | the narrowest access that owes a doc for `missing-doc`: `public`, `package`, or `internal` (the default) |

Warnings print as `warning:` and leave the exit status 0, so a team can bring a rule in before it gates
anything. A key or rule code SwiftLucid doesn't know stops the run, so a typo can't leave a rule on
unnoticed.

## Environment

| Variable | Does |
| --- | --- |
| `SWIFTLUCID_TIMING=1` | prints every timed phase to standard error; they're also in Instruments and `log stream --predicate 'subsystem == "swiftlucid"'` |

## The package

| Target | Holds |
| --- | --- |
| `LucidRead` | one pass over the sources: declarations, doc comments, links, and git revisions |
| `LucidLint` | the house style: the rules, their findings, which declarations owe a doc, and what a change touched |
| `swiftlucid` | the command line |

Each depends only on the ones above it, and `LucidRead` depends only on swift-syntax. A tool that shows
docs, such as [gloss](https://github.com/acfriedman/gloss), builds on the two libraries: it reads with
`LucidRead` and shows `LucidLint`'s findings beside what the docs say.

## License

Copyright 2026 Andrew C. Friedman. Licensed under the [MIT License](LICENSE).
