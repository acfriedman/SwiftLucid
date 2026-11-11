import LucidRead

/// The findings that fall on what a change touched: the declarations it added or changed, bodies
/// included, so a commit hook or a pull request's check judges the change and not the code around it.
///
/// Code nobody touched keeps its old findings without failing the change, so a project can bring its
/// house style in as it goes, while a declaration that changed at all answers to the style in full. A
/// declaration is matched by name, never by place: by the types around it, its keyword, and its name as a
/// caller writes it. So code that only moved, within a file or to another module, touches nothing, and
/// neither does a declaration that is gone. A module the change touched answers for its page too, so a
/// new public type its page does not list is caught in the change that adds it.
public struct ChangedFindings: Sendable {
    /// The lines of each declaration the change added or changed, by file as the head names it.
    public private(set) var touched: [String: [ClosedRange<Int>]] = [:]
    /// How many declarations the change added or changed.
    public private(set) var count = 0

    /// Finds the declarations a change added or changed, and where they are.
    ///
    /// - Parameters:
    ///   - base: The sources before the change.
    ///   - head: The sources after it, as the lint reads them.
    public init(base: Reading, head: Reading) {
        let before = Dictionary(grouping: Self.declarations(in: base), by: \.key)
        for (key, now) in Dictionary(grouping: Self.declarations(in: head), by: \.key) {
            let partners = Self.partners(base: before[key] ?? [], head: now)
            for (index, declaration) in now.enumerated() {
                guard let match = partners[index] else {
                    touch(declaration)
                    continue
                }
                if match.header != declaration.header || match.doc != declaration.doc || match.body != declaration.body {
                    touch(declaration)
                }
            }
        }
    }

    /// Keeps the diagnostics on a new or changed declaration, on its doc comment or on the declaration,
    /// and those on the page of a module the change touched.
    ///
    /// - Parameter diagnostics: What the lint found in the head.
    /// - Returns: The ones on lines a touched declaration takes or about a touched module's page, in the
    ///   same order.
    public func filter(_ diagnostics: [Diagnostic]) -> [Diagnostic] {
        let modules = Set(touched.keys.map(SourceFiles.module(of:)))
        return diagnostics.filter { diagnostic in
            let aboutPage = ModulePage.isPage(diagnostic.file) || diagnostic.rule == .moduleDocMissing
            if aboutPage { return modules.contains(SourceFiles.module(of: diagnostic.file)) }
            return touched[diagnostic.file]?.contains { $0.contains(diagnostic.line) } ?? false
        }
    }

    /// Records a declaration as one the change added or changed.
    ///
    /// - Parameter declaration: The declaration, as the head reads it.
    private mutating func touch(_ declaration: Compared) {
        touched[declaration.file, default: []].append(declaration.lines)
        count += 1
    }

    /// One declaration as a change compares it: what it is matched by and what a change to it is.
    private struct Compared {
        /// What it is matched by: the types around it, its keyword, and its name as a caller writes it.
        var key: String
        /// The module it is in, which a match prefers to keep.
        var module: String
        /// The declaration as written, without its body or doc comment.
        var header: String
        /// What its doc says, with the comment's line breaks read as spaces, so rewrapping is no change.
        var doc: String
        /// A fingerprint of what it does: its body, accessors, or initial value.
        var body: String?
        /// The file it is in, as reported.
        var file: String
        /// The lines it takes, its doc comment's first through its last.
        var lines: ClosedRange<Int>
    }

    /// Every declaration a reading holds, as a change compares it.
    ///
    /// - Parameter reading: The sources read.
    /// - Returns: The declarations, file by file, each file's in source order.
    private static func declarations(in reading: Reading) -> [Compared] {
        reading.files.flatMap { file in
            file.entries.map { entry in
                let keyword = entry.details.keyword
                var name = entry.declaration.name
                if ["func", "init", "subscript", "macro"].contains(keyword) {
                    name += "(" + (entry.declaration.parameters ?? []).map { ($0.label ?? "_") + ":" }.joined() + ")"
                }
                let doc = (entry.doc?.lines ?? []).map(\.text).joined(separator: " ")
                    .split(whereSeparator: \.isWhitespace).joined(separator: " ")
                return Compared(key: (entry.details.container + [keyword + " " + name]).joined(separator: "\u{0}"),
                                module: SourceFiles.module(of: file.file), header: entry.details.header, doc: doc,
                                body: entry.details.bodyFingerprint, file: file.file, lines: entry.details.lines)
            }
        }
    }

    /// Pairs the declarations alike in the head with those in the base: first the ones written the same
    /// in the same module, then those written the same anywhere, then the rest in order, the same module
    /// first.
    ///
    /// - Parameters:
    ///   - base: The declarations with one key in the base, in source order.
    ///   - head: The declarations with that key in the head, in source order.
    /// - Returns: For each head declaration's index, its partner in the base; a new one has none.
    private static func partners(base: [Compared], head: [Compared]) -> [Int: Compared] {
        var unmatched = Array(base.indices)
        var partner: [Int: Compared] = [:]
        let passes: [(Compared, Compared) -> Bool] = [
            { $0.module == $1.module && $0.header == $1.header },
            { $0.header == $1.header },
            { $0.module == $1.module },
            { _, _ in true }
        ]
        for alike in passes {
            for (index, declaration) in head.enumerated() where partner[index] == nil {
                guard let found = unmatched.firstIndex(where: { alike(base[$0], declaration) }) else { continue }
                partner[index] = base[unmatched.remove(at: found)]
            }
        }
        return partner
    }
}
