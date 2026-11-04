//
//  NovemberLeavesTests.swift
//  FurlingTests
//
//  The date and counting rules behind November's leaves. Wrong answers here
//  are quiet — a leaf too many, a rabbit on the wrong day, leaves in
//  December — so the edges are what these pin.
//

import Foundation
import Testing

struct NovemberLeavesTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ month: Int, _ day: Int, hour: Int = 12, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func theFirstAndLastDaysOfNovemberAreOneAndThirty() {
        #expect(NovemberLeaves.dayOfNovember(date(11, 1), calendar: calendar) == 1)
        #expect(NovemberLeaves.dayOfNovember(date(11, 30), calendar: calendar) == 30)
    }

    @Test func nothingFallsOutsideNovember() {
        #expect(NovemberLeaves.dayOfNovember(date(10, 31), calendar: calendar) == nil)
        #expect(NovemberLeaves.dayOfNovember(date(12, 1), calendar: calendar) == nil)
        #expect(NovemberLeaves.dayOfNovember(date(5, 15), calendar: calendar) == nil)
    }

    @Test func midnightBelongsToTheNewDay() {
        #expect(NovemberLeaves.dayOfNovember(date(11, 1, hour: 0), calendar: calendar) == 1)
        #expect(NovemberLeaves.dayOfNovember(date(12, 1, hour: 0), calendar: calendar) == nil)
    }

    @Test func itComesBackEveryYear() {
        #expect(NovemberLeaves.dayOfNovember(date(11, 12, year: 2029), calendar: calendar) == 12)
    }

    @Test func oneMoreFallerEachDay() {
        #expect(NovemberLeaves.fallerCount(onDay: 1) == 1)
        #expect(NovemberLeaves.fallerCount(onDay: 30) == 30)
    }

    @Test func everyFifthFallerIsARabbit() {
        let rabbits = (0..<30).filter(NovemberLeaves.isRabbit)
        #expect(rabbits == [4, 9, 14, 19, 24, 29])
    }

    @Test func noRabbitBeforeTheFifth() {
        for day in 1...4 {
            let count = NovemberLeaves.fallerCount(onDay: day)
            #expect((0..<count).filter(NovemberLeaves.isRabbit).isEmpty, "on November \(day)")
        }
    }

    @Test func rabbitCountMatchesWhatActuallyFalls() {
        for day in 1...30 {
            let count = NovemberLeaves.fallerCount(onDay: day)
            let falling = (0..<count).filter(NovemberLeaves.isRabbit).count
            #expect(falling == NovemberLeaves.rabbitCount(onDay: day), "on November \(day)")
        }
        #expect(NovemberLeaves.rabbitCount(onDay: 30) == 6)
    }

    @Test func electionDayIsTheTuesdayAfterTheFirstMonday() {
        #expect(NovemberLeaves.isElectionDay(date(11, 3), calendar: calendar))
        #expect(NovemberLeaves.isElectionDay(date(11, 2, year: 2027), calendar: calendar))
        #expect(NovemberLeaves.isElectionDay(date(11, 7, year: 2028), calendar: calendar))
        // 1 November 2033 is a Tuesday, but no Monday has come yet.
        #expect(!NovemberLeaves.isElectionDay(date(11, 1, year: 2033), calendar: calendar))
        #expect(NovemberLeaves.isElectionDay(date(11, 8, year: 2033), calendar: calendar))
        #expect(!NovemberLeaves.isElectionDay(date(11, 4), calendar: calendar))
    }
}
