# Advanced

## How a change is judged

`--staged` and `--since` read the whole project as the change leaves it, so links into files the change
did not touch still resolve, and report only the findings on declarations it added or changed.

- **A change** is a new declaration, or one whose declaration as written, doc, or body differs. A body
  counts when what it does differs, not when it is only reformatted or commented, and a body edit makes
  the declaration's doc that change's to fix.
- **Declarations are matched by name,** never by place: the types around them, their keyword, and their
  name as a caller writes it, overloads by how they are written. Code that only moved, within a file or
  to another module, touches nothing, and neither does a declaration that is gone.
- **A module the change touched answers for its page,** so a new public type its page doesn't list is
  caught in the change that adds it.
- **`--staged`** judges git's index against `HEAD`, which is exactly what the commit will hold; a first
  commit, with no `HEAD`, is all new. **`--since <revision>`** judges the working tree against the
  revision.

## The libraries

SwiftLucid's two layers are libraries a tool can build on:

| Library | Holds |
| --- | --- |
| `LucidRead` | one pass over the sources: declarations, doc comments, links, and git revisions |
| `LucidLint` | the house style: the rules, their findings, which declarations owe a doc, and what a change touched |

```swift
.package(url: "https://github.com/acfriedman/SwiftLucid", from: "0.2.0")
// in a target's dependencies:
.product(name: "LucidLint", package: "SwiftLucid")
```

`LucidLint` depends only on `LucidRead`, and `LucidRead` only on swift-syntax. A tool that shows docs,
such as [gloss](https://github.com/acfriedman/gloss), reads with `LucidRead` and shows `LucidLint`'s
findings beside what the docs say. Each module's `README.md` under `Sources` lists its types.

## Timing

`SWIFTLUCID_TIMING=1` prints every timed phase to standard error, such as parsing, indexing, and git.
The same phases are intervals in Instruments, under Points of Interest, and debug lines in the unified
log:

```bash
log stream --level debug --predicate 'subsystem == "swiftlucid"'
```
