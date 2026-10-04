//
//  Changelog.swift
//  Furling
//
//  Reads changelog.md out of the app bundle and turns it into entries for
//  the "new & noteworthy" section in Settings. The markdown file is the
//  single source of truth — nothing here is hand-maintained.
//

import Foundation

struct ChangelogEntry: Identifiable {
    /// Build number, which is also what entries are keyed by in the markdown.
    let id: Int
    let date: Date
    let categories: [Category]

    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let items: [String]
    }
}

enum Changelog {
    static func load() -> [ChangelogEntry] {
        guard
            let url = Bundle.main.url(forResource: "changelog", withExtension: "md"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        return parse(text)
    }

    /// Expects Keep a Changelog shape: `## [build N] - yyyy-MM-dd`, then
    /// `### category`, then `- item` bullets. Anything else is ignored, so
    /// the preamble passes through harmlessly.
    static func parse(_ text: String) -> [ChangelogEntry] {
        let dates = DateFormatter()
        dates.calendar = Calendar(identifier: .gregorian)
        dates.locale = Locale(identifier: "en_US_POSIX")
        dates.dateFormat = "yyyy-MM-dd"

        var entries: [ChangelogEntry] = []
        var build: Int?
        var date: Date?
        var categories: [ChangelogEntry.Category] = []
        var categoryName: String?
        var items: [String] = []

        func closeCategory() {
            if let categoryName, !items.isEmpty {
                categories.append(.init(name: categoryName, items: items))
            }
            categoryName = nil
            items = []
        }

        func closeEntry() {
            closeCategory()
            if let build, let date, !categories.isEmpty {
                entries.append(.init(id: build, date: date, categories: categories))
            }
            build = nil
            date = nil
            categories = []
        }

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("## [build ") {
                closeEntry()
                let rest = line.dropFirst("## [build ".count)
                build = Int(rest.prefix { $0.isNumber })
                if let separator = line.range(of: "] - ") {
                    date = dates.date(from: String(line[separator.upperBound...]))
                }
            } else if line.hasPrefix("### ") {
                closeCategory()
                categoryName = String(line.dropFirst(4))
            } else if line.hasPrefix("- ") {
                items.append(String(line.dropFirst(2)))
            } else if !line.isEmpty, !items.isEmpty, rawLine.hasPrefix(" ") {
                // An indented line under a bullet is that bullet wrapped, not
                // a new one. Markdown reads it as one item and so should we —
                // without this the tail of a long entry vanishes silently.
                items[items.count - 1] += " " + line
            }
        }
        closeEntry()

        return entries.sorted { $0.id > $1.id }
    }
}
