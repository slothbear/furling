//
//  DistanceStore.swift
//  Furling
//
//  IMPORTANT: add this file to BOTH target memberships (Furling and
//  FurlingWidgetExtension). Select the file, open the File Inspector on the
//  right, and tick both boxes under "Target Membership".
//

import Foundation
import HealthKit

enum DistanceStore {

    /// Must match the App Group in Signing & Capabilities on both targets,
    /// and the identifier in both .entitlements files. A mismatch fails
    /// silently: `UserDefaults(suiteName:)` still hands back a store, but it
    /// is the process's own, so the app and the widget never see each other's
    /// writes and the cached reading never arrives.
    static let appGroup = "group.com.morganthall.furling"

    private static let healthStore = HKHealthStore()
    private static let distanceType = HKQuantityType(.distanceWalkingRunning)

    // MARK: - Authorization

    /// Asks for read access to walking + running distance. Safe to call
    /// repeatedly; iOS only shows the sheet the first time.
    static func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw DistanceError.healthUnavailable
        }
        try await healthStore.requestAuthorization(toShare: [], read: [distanceType])
    }

    // MARK: - Reading

    /// Walking + running distance over a span, in miles.
    ///
    /// This is HealthKit's own distance figure, derived from GPS and the
    /// motion coprocessor's stride estimate. It is not steps multiplied by an
    /// assumed stride length, and it will not match that calculation.
    static func miles(from start: Date, to end: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    // HealthKit reports "no data" as an error rather than an
                    // empty sum. That's still a legitimate zero — nobody
                    // walked in that span — not a read failure.
                    if let hkError = error as? HKError, hkError.code == .errorNoData {
                        continuation.resume(returning: 0)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                // No samples in the span is a legitimate zero, not an error.
                let value = statistics?.sumQuantity()?.doubleValue(for: .mile()) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    /// Distance since midnight. The only reading that gets cached, since the
    /// cache exists to stand in for today.
    static func milesToday() async throws -> Double {
        let miles = try await miles(from: Calendar.current.startOfDay(for: Date()), to: Date())
        cache(miles)
        return miles
    }

    /// Yesterday's total, or nil if it couldn't be read. Nil rather than zero
    /// so the caller can drop the line entirely — a zero here would claim you
    /// didn't walk yesterday, which isn't what a failed read means.
    static func milesYesterday() async -> Double? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)
        else { return nil }
        return try? await miles(from: startOfYesterday, to: startOfToday)
    }

    // MARK: - Fallback cache

    // HealthKit lives in protected storage and reads fail whenever the phone
    // is locked, not only between a reboot and the first unlock. These
    // defaults stay readable once the phone has been unlocked at least once
    // since boot, so stashing each successful reading in the shared App Group
    // covers the case that recurs all day: a widget timeline refresh landing
    // while the phone sits locked. Before that first unlock both are dark and
    // there is nothing to show.

    private static let milesKey = "cachedMiles"
    private static let stampKey = "cachedMilesDate"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    private static func cache(_ miles: Double) {
        defaults?.set(miles, forKey: milesKey)
        defaults?.set(Date(), forKey: stampKey)
    }

    /// The last reading we managed to take, but only if it is still from
    /// today. Yesterday's mileage would be worse than showing nothing.
    static func cachedMiles() -> Double? {
        guard let defaults,
              let stamp = defaults.object(forKey: stampKey) as? Date,
              Calendar.current.isDateInToday(stamp)
        else { return nil }
        return defaults.double(forKey: milesKey)
    }

    // MARK: - Reading state

    /// What the display is actually showing, so the UI can be honest about
    /// where the number came from.
    enum Reading: Equatable {
        /// HealthKit answered. Zero here is a real zero.
        case live(Double)
        /// The query failed; this is the last good value from earlier today.
        case stale(Double)
        /// The query failed and there was nothing cached. Showing zero.
        case unavailable

        var miles: Double {
            switch self {
            case .live(let m), .stale(let m): return m
            case .unavailable: return 0
            }
        }
    }

    /// Never throws. Degrades from live, to cached, to zero.
    static func reading() async -> Reading {
        do {
            return .live(try await milesToday())
        } catch {
            if let cached = cachedMiles() { return .stale(cached) }
            return .unavailable
        }
    }

    // MARK: - Formatting

    /// One decimal place: "3.7 mi". Change to "%.2f mi" for two.
    static func short(_ miles: Double) -> String {
        String(format: "%.1f mi", miles)
    }
}

enum DistanceError: LocalizedError {
    case healthUnavailable

    var errorDescription: String? {
        switch self {
        case .healthUnavailable:
            return "This device doesn't provide Health data."
        }
    }
}
