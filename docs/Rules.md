# Rules

Every rule below is on by default, as an error. A project turns any of them down to a warning or off in
`.swiftlucid.json` ([Configuration](Configuration.md)), by its code or a prefix such as `summary-*`.

## The shape of a doc

A doc comment is a one- or two-sentence summary, what the declaration does and then why it exists, a
blank line, then a markup entry for every parameter, the return value, and what it throws:

```swift
/// Charges the shopper for the cart, so checkout can hand back a receipt.
///
/// - Parameter amount: The total, in cents.
/// - Returns: The receipt for the charge.
/// - Throws: ``PaymentError`` when the card is declined.
func charge(_ amount: Int) throws -> Receipt
```

Types, properties, and enum cases get only the summary rules. Code fences in a comment are quoted, not
checked.

## Codes

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

## Exemptions

A protocol requirement inherits the protocol's doc, so SwiftLucid skips:
- **known requirements** by signature, such as `hash(into:)`, `init(from:)`, `body`, and `description`;
- **members of a conformance extension** (`extension T: P`), for `missing-doc` only;
- **memberwise initializers**, whose body only assigns their parameters;
- **anything marked** `// swiftlucid:exempt <reason>` on the line above.

## Module pages

Each module under `Sources` keeps a `README.md` that says what it does and groups its types, short enough
to read at a glance, and the lint keeps it in step with the code:

```markdown
# Shop

Sells what a shopper picks, so checkout has one place to ask.

## Overview

A ``Cart`` holds what the shopper picked. (Five sentences at most.)

## Topics

### Carts

- ``Cart``
- ``Line``
```

The summary answers to the same rules as a doc's, a link must name something, and every public type
must be linked somewhere on the page. SwiftPM wants each target to leave the file out of the build:
`exclude: ["README.md"]`. A project that doesn't want pages turns `module-doc-*` off.
