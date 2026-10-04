//
//  OctoberOrnamentTests.swift
//  FurlingTests
//
//  The date arithmetic behind the candy corn. A wrong answer here is never a
//  crash — it is a candy corn that is a day early, or a caption that is
//  quietly wrong — so the edges (the first and last of the month, midnight,
//  the day either side) are what these pin.
//

import Foundation
import Testing

struct OctoberOrnamentTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - Which day

    @Test func theFirstAndLastDaysOfOctoberAreOneAndThirtyOne() {
        #expect(OctoberOrnament.dayOfOctober(date(10, 1), calendar: calendar) == 1)
        #expect(OctoberOrnament.dayOfOctober(date(10, 31), calendar: calendar) == 31)
    }

    @Test func nothingShowsOutsideOctober() {
        #expect(OctoberOrnament.dayOfOctober(date(9, 30), calendar: calendar) == nil)
        #expect(OctoberOrnament.dayOfOctober(date(11, 1), calendar: calendar) == nil)
        #expect(OctoberOrnament.dayOfOctober(date(3, 15), calendar: calendar) == nil)
        #expect(OctoberOrnament.caption(date(11, 1), calendar: calendar) == nil)
    }

    @Test func lateInTheDayIsStillThatDay() {
        #expect(OctoberOrnament.dayOfOctober(date(10, 4, hour: 23, minute: 59), calendar: calendar) == 4)
        #expect(OctoberOrnament.dayOfOctober(date(10, 5, hour: 0, minute: 0), calendar: calendar) == 5)
    }

    @Test func itComesBackEveryYear() {
        #expect(OctoberOrnament.dayOfOctober(date(10, 15, year: 2027), calendar: calendar) == 15)
        #expect(OctoberOrnament.isHalloween(date(10, 31, year: 2031), calendar: calendar))
    }

    // MARK: - Counting down

    @Test func daysRemainingCountDownToZeroOnHalloween() {
        #expect(OctoberOrnament.daysUntilHalloween(date(10, 4), calendar: calendar) == 27)
        #expect(OctoberOrnament.daysUntilHalloween(date(10, 30), calendar: calendar) == 1)
        #expect(OctoberOrnament.daysUntilHalloween(date(10, 31), calendar: calendar) == 0)
    }

    @Test func daysElapsedAndDaysRemainingAlwaysMakeThirtyOne() {
        for day in 1...31 {
            let when = date(10, day)
            let elapsed = OctoberOrnament.dayOfOctober(when, calendar: calendar)!
            let remaining = OctoberOrnament.daysUntilHalloween(when, calendar: calendar)!
            #expect(elapsed + remaining == 31, "on October \(day)")
        }
    }

    @Test func onlyTheThirtyFirstIsHalloween() {
        #expect(OctoberOrnament.isHalloween(date(10, 31), calendar: calendar))
        #expect(OctoberOrnament.isHalloween(date(10, 31, hour: 23, minute: 59), calendar: calendar))
        #expect(!OctoberOrnament.isHalloween(date(10, 30), calendar: calendar))
        #expect(!OctoberOrnament.isHalloween(date(11, 1, hour: 0, minute: 0), calendar: calendar))
    }

    // MARK: - Captions

    @Test func captionsReadCorrectlyIncludingTheSingular() {
        #expect(OctoberOrnament.caption(date(10, 4), calendar: calendar) == "27 days to Halloween")
        #expect(OctoberOrnament.caption(date(10, 30), calendar: calendar) == "1 day to Halloween")
        #expect(OctoberOrnament.caption(date(10, 31), calendar: calendar) == "happy Halloween")
    }

    @Test func halloweenKeepsItsCapitalAndTheRestStaysLowercase() {
        // "Halloween" is a name; a caption is a fragment, so nothing else
        // starts with a capital or a digit-led sentence case.
        for day in 1...31 {
            let caption = OctoberOrnament.caption(date(10, day), calendar: calendar)!
            #expect(caption.contains("Halloween"), "on October \(day)")
            #expect(caption.first!.isLowercase || caption.first!.isNumber, "on October \(day)")
        }
    }

    // MARK: - Colour bands

    @Test func theBandsAreThirdsCountedFromTheBase() {
        let bands = (0..<OctoberOrnament.sliceCount).map(OctoberOrnament.band(forSlice:))
        #expect(bands.first == 0)
        #expect(bands.last == 2)
        #expect(bands.filter { $0 == 0 }.count == 11)
        #expect(bands.filter { $0 == 1 }.count == 10)
        #expect(bands.filter { $0 == 2 }.count == 10)
    }

    @Test func theBandsOnlyEverRiseAsYouClimb() {
        let bands = (0..<OctoberOrnament.sliceCount).map(OctoberOrnament.band(forSlice:))
        #expect(bands == bands.sorted())
    }

    @Test func oneSlicePerDayOfOctober() {
        #expect(OctoberOrnament.sliceCount == 31)
    }
}
