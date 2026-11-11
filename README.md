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

## Getting started

```bash
git clone https://github.com/acfriedman/SwiftLucid && cd SwiftLucid
swift build -c release
.build/release/swiftlucid path/to/YourProject/Sources
```

Each finding is one line in compiler format, so Xcode and GitHub Actions show it as is, and the exit status
is 1 when any is an error, so the same command gates CI. A folder is walked for `.swift` files, and for `.h`
files whose Objective-C types the docs may link, skipping hidden folders and those dependency managers
fill: `SourcePackages`, `DerivedData`, `Pods`, and `Carthage`. Build for release: a debug build is several
times slower on a large codebase.

## Usage

| Command | Does |
| --- | --- |
| `swiftlucid <paths>` | lints; `--include-tests` reads `*Tests` folders too, `--summary` prints only counts by rule, `--style <file>` reads a house style other than the nearest |
| `swiftlucid --staged <paths>` | lints only the declarations the next commit adds or changes, for a pre-commit hook |
| `swiftlucid --since <rev> <paths>` | lints only the declarations changed since a revision, for a pull request's check |

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

## Hooks and CI

A codebase that predates its house style has findings nobody will fix at once. `--staged` and `--since`
read the whole project, so links into untouched files resolve, but report only the declarations the
change added or changed, a body edit included. A declaration is matched by name, so code that only moved
touches nothing. New and touched code answers to the style; the rest is left alone until someone works on
it.

```bash
#!/bin/sh
# .git/hooks/pre-commit: judge what this commit holds, staged edits only
exec swiftlucid --staged .
```

In CI, `swiftlucid --since origin/main .` judges a branch the same way. A build phase can keep linting
everything, with the house style's warnings keeping old findings from failing the build.

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
