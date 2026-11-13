# Usage

```
swiftlucid [--include-tests] [--summary] [--style <file>] [--staged | --since <revision>] <path>...
swiftlucid --version
```

With no `--staged` or `--since`, SwiftLucid judges every declaration under the paths. With either, it
reads the whole project but judges only what a change added or changed; [Advanced](Advanced.md#how-a-change-is-judged)
says how a change is found.

## Flags

| Flag | Does |
| --- | --- |
| `--staged` | judges the declarations the next commit adds or changes: git's index against `HEAD`, for a pre-commit hook |
| `--since <revision>` | judges the declarations changed since a revision: the working tree against it, for a build phase or a pull request's check |
| `--include-tests` | reads `*Tests` folders too, which are skipped by default |
| `--summary` | prints only the counts by rule, not each finding |
| `--style <file>` | reads this house style instead of the nearest `.swiftlucid.json` ([Configuration](Configuration.md)) |
| `--version` | prints the version |
| `--help` | prints the usage |

## Output

Each finding is one line on standard output, in compiler format, so Xcode shows it beside the code:

```
Sources/Shop/Cart.swift:12:5: error: The summary must end with a period. [summary-terminator]
```

The bracketed code names the rule ([Rules](Rules.md)), and is what `.swiftlucid.json` sets levels by. A
summary follows on standard error: the errors and warnings, what was judged, and the count for each rule.

## Exit status

| Status | Means |
| --- | --- |
| `0` | no errors; warnings alone still pass |
| `1` | at least one error |
| `64` | the command line is wrong: an unknown flag, a flag without its value, or no paths |
| `65` | the house style cannot be read, or git cannot read the index or the revision |
| `66` | a path does not exist, so a typo cannot pass as a clean run |

## What it reads

A path may be a file or a folder. A folder is walked for:
- **`.swift` files**, each declaration and its doc comment;
- **`.h` files**, for the Objective-C type names Swift docs may link in a mixed project; their members
  are taken on trust;
- **module pages**, the `README.md` right under `Sources/<Module>/` ([Rules](Rules.md#module-pages)).

It skips hidden folders, the folders dependency managers fill (`SourcePackages`, `DerivedData`, `Pods`,
and `Carthage`), folders ending in `Tests` unless `--include-tests` is given, and package manifests. Files
a house style excludes are still read, so links into them resolve; they are only not judged.
