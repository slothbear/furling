//
//  ChangelogTests.swift
//  FurlingTests
//
//  Changelog.parse fails by going quiet rather than by crashing: a line it
//  does not recognise is dropped without a trace. These pin the behaviour
//  that has already gone wrong once, and the behaviour that is deliberate.
//

import Foundation
import Testing

struct ChangelogParsingTests {

    private func day(_ entry: ChangelogEntry) -> DateComponents {
        Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: entry.date)
    }

    // MARK: - The shape it expects

    @Test func parsesBuildsCategoriesAndBullets() {
        let entries = Changelog.parse("""
        ## [build 2] - 2026-08-13

        ### added
        - first
        - second

        ### changed
        - third
        """)

        #expect(entries.count == 1)
        let entry = entries[0]
        #expect(entry.id == 2)
        #expect(day(entry) == DateComponents(year: 2026, month: 8, day: 13))
        #expect(entry.categories.map(\.name) == ["added", "changed"])
        #expect(entry.categories[0].items == ["first", "second"])
        #expect(entry.categories[1].items == ["third"])
    }

    @Test func categoryNamesKeepTheCaseTheyAreWrittenIn() {
        let entries = Changelog.parse("""
        ## [build 1] - 2026-08-13
        ### Added
        - x
        """)
        #expect(entries[0].categories[0].name == "Added")
    }

    @Test func emptyInputGivesNoEntries() {
        #expect(Changelog.parse("").isEmpty)
    }

    // MARK: - Wrapped bullets

    @Test func aWrappedBulletIsOneItem() {
        let entries = Changelog.parse("""
        ## [build 5] - 2026-10-04
        ### fixed
        - While the phone is locked, the widget now shows your last known reading.
          Previously it may have displayed the warning symbol.
        """)

        #expect(entries[0].categories[0].items == [
            "While the phone is locked, the widget now shows your last known reading. Previously it may have displayed the warning symbol."
        ])
    }

    @Test func aBulletCanWrapOverSeveralLines() {
        let entries = Changelog.parse("""
        ## [build 1] - 2026-08-13
        ### added
        - one
          two
            three
        - next
        """)
        #expect(entries[0].categories[0].items == ["one two three", "next"])
    }

    @Test func aWrappedLineBelongsToTheBulletAboveItNotTheOneBelow() {
        let entries = Changelog.parse("""
        ## [build 1] - 2026-08-13
        ### added
        - a
          continues a
        - b
        """)
        #expect(entries[0].categories[0].items == ["a continues a", "b"])
    }

    @Test func anIndentedLineWithNoBulletAboveItIsIgnored() {
        let entries = Changelog.parse("""
        ## [build 1] - 2026-08-13
        ### added
          orphan
        - real
        """)
        #expect(entries[0].categories[0].items == ["real"])
    }

    @Test func unindentedProseBetweenBulletsIsNotAContinuation() {
        let entries = Changelog.parse("""
        ## [build 1] - 2026-08-13
        ### added
        - a
        this is prose, not a wrapped line
        - b
        """)
        #expect(entries[0].categories[0].items == ["a", "b"])
    }

    // MARK: - Things that must stay out

    @Test func preambleBeforeTheFirstBuildIsIgnored() {
        let entries = Changelog.parse("""
        # changelog

        All noteworthy changes to Furling are documented here.

        This project doesn't use semantic versioning.

        ## [build 1] - 2026-08-13
        ### added
        - only this
        """)

        #expect(entries.count == 1)
        #expect(entries[0].categories[0].items == ["only this"])
    }

    @Test func aBuildWithNoBulletsIsSkipped() {
        let entries = Changelog.parse("""
        ## [build 6] - 2026-10-04

        ## [build 5] - 2026-10-04
        ### added
        - something
        """)
        #expect(entries.map(\.id) == [5])
    }

    @Test func aCategoryWithNoBulletsIsSkipped() {
        let entries = Changelog.parse("""
        ## [build 1] - 2026-08-13
        ### added
        ### changed
        - something
        """)
        #expect(entries[0].categories.map(\.name) == ["changed"])
    }

    // MARK: - Ordering

    @Test func buildsAreReturnedNewestFirstWhateverOrderTheyAreWritten() {
        let entries = Changelog.parse("""
        ## [build 2] - 2026-08-13
        ### added
        - b
        ## [build 10] - 2026-10-04
        ### added
        - j
        ## [build 1] - 2026-08-12
        ### added
        - a
        """)
        #expect(entries.map(\.id) == [10, 2, 1])
    }

    // MARK: - Dates

    // Pins current behaviour, and it is the quiet kind: a heading with no date
    // discards the whole build rather than showing it undated. That may not be
    // what is wanted, but it is what happens, and a test is the only thing
    // that will say so if it changes.

    @Test func aMissingDateDropsTheWholeBuild() {
        let entries = Changelog.parse("""
        ## [build 3]
        ### added
        - lost
        """)
        #expect(entries.isEmpty)
    }

    // MARK: - The file that ships

    @Test func everyBuildInTheRealChangelogComesThrough() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Furling/changelog.md")
        let text = try String(contentsOf: url, encoding: .utf8)

        let headings = text.split(separator: "\n").filter { $0.hasPrefix("## [build ") }
        let entries = Changelog.parse(text)

        #expect(!headings.isEmpty)
        #expect(entries.count == headings.count,
                "a build heading in changelog.md was silently dropped by the parser")
        for entry in entries {
            #expect(!entry.categories.isEmpty)
            for category in entry.categories {
                #expect(!category.items.isEmpty)
            }
        }
    }
}
