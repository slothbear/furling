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

    /// Must match the App Group you create in Signing & Capabilities,
    /// on both targets.
    static let appGroup = "group.com.yourname.furling"

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

    /// Walking + running distance since midnight, in miles.
    ///
    /// This is HealthKit's own distance figure, derived from GPS and the
    /// motion coprocessor's stride estimate. It is not steps multiplied by an
    /// assumed stride length, and it will not match that calculation.
    static func milesToday() async throws -> Double {
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        let miles: Double = try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                // No samples yet today is a legitimate zero, not an error.
                let value = statistics?.sumQuantity()?.doubleValue(for: .mile()) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }

        cache(miles)
        return miles
    }

    // MARK: - Fallback cache

    // HealthKit lives in protected storage. Between a reboot and the first
    // unlock, queries fail outright. Stashing each successful reading in the
    // shared App Group lets the widget show the last real number instead of
    // a dash.

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
