# SwiftLucid

A linter for Swift doc comments. It keeps every declaration explaining itself, in the shape Swift's doc
format and DocC expect, and it can judge just the code a commit touches, so an existing codebase can
start today.

## Why

Doc comments are the documentation closest to the code, and the first to drift: a parameter is added and
its entry isn't, a link names a type that was renamed, a summary trails off. The compiler checks none of
it. SwiftLucid does:

- **One shape for every doc.** A one- or two-sentence summary, what it does and then why, then a
  `- Parameter`, `- Returns:`, and `- Throws:` entry for everything the signature has. Quick Help, DocC,
  and a reviewer all read the same thing.
- **Links that can't rot.** A ``` ``Type/member`` ``` link must name something the code declares.
- **Starts with what you change.** As a commit hook it judges only the declarations a commit adds or
  changes, so new code meets the bar without a cleanup of the old.
- **Your house style.** Every rule can be an error, a warning, or off.

This doc gets six findings:

```swift
/// charges the cart
func charge(_ amount: Int) throws -> Receipt
```

Among them, each saying how to fix it:

```
Cart.swift:1:1: error: Parameter `amount` of `charge(_:)` is not documented. Add `- Parameter amount: <what it is, its range or nil meaning>`. [parameter-missing]
Cart.swift:1:1: error: `charge` throws but has no `- Throws:` entry; name each error and what triggers it. [throws-missing]
Cart.swift:1:1: error: The summary must end with a period. [summary-terminator]
```

And this one passes:

```swift
/// Charges the shopper for the cart, so checkout can hand back a receipt.
///
/// - Parameter amount: The total, in cents.
/// - Returns: The receipt for the charge.
/// - Throws: ``PaymentError`` when the card is declined.
func charge(_ amount: Int) throws -> Receipt
```

## Get started

SwiftLucid needs macOS 14+ and Swift 6 (Xcode 16 or later).

1. Install it with [Mint](https://github.com/yonaskolb/Mint), and put `~/.mint/bin` on your `PATH`:

   ```bash
   mint install acfriedman/SwiftLucid
   ```

2. Lint your sources:

   ```bash
   swiftlucid Sources
   ```

3. Judge every commit from now on, only what it adds or changes:

   ```bash
   printf '#!/bin/sh\nexec swiftlucid --staged .\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
   ```

4. To adopt it gradually, start with warnings in `.swiftlucid.json`, which report findings without
   failing anything:

   ```json
   { "severity": "warning" }
   ```

## Learn more

| Guide | Covers |
| --- | --- |
| [Installation](docs/Installation.md) | Mint, a version pinned in your repository, building from source |
| [Usage](docs/Usage.md) | every flag, the output, exit codes, and which files are read |
| [Setup](docs/Setup.md) | commit hooks for Git apps and teams, the pre-commit framework, Xcode, CI |
| [Rules](docs/Rules.md) | each rule's code, what's exempt, and module pages |
| [Configuration](docs/Configuration.md) | `.swiftlucid.json`: rule levels, excluded paths, which access owes a doc |
| [Advanced](docs/Advanced.md) | how a change is judged, the libraries, timing |

## License

Copyright 2026 Andrew C. Friedman. Licensed under the [MIT License](LICENSE).
