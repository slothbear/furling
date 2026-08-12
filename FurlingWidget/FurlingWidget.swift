//
//  FurlingWidget.swift
//  FurlingWidget
//
//  .accessoryInline is the strip beside the lock screen date. It gets one
//  line, the system font, one optional SF Symbol, and a single tint colour
//  applied by the OS. Anything else you set here is discarded, so the design
//  work is entirely in choosing what fits.
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct MilesEntry: TimelineEntry {
    let date: Date
    /// nil means we couldn't reach HealthKit and had no usable cache.
    let miles: Double?
}

// MARK: - Provider

struct MilesProvider: TimelineProvider {

    func placeholder(in context: Context) -> MilesEntry {
        MilesEntry(date: Date(), miles: 3.7)
    }

    func getSnapshot(in context: Context, completion: @escaping (MilesEntry) -> Void) {
        // The widget gallery renders a snapshot; querying Health there is
        // slow and may be unauthorized, so show a representative value.
        if context.isPreview {
            completion(MilesEntry(date: Date(), miles: 3.7))
            return
        }
        Task { completion(await reading()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MilesEntry>) -> Void) {
        Task {
            let entry = await reading()

            // Ask again in 15 minutes, or at midnight if that comes first, so
            // the counter resets promptly for the new day. WidgetKit budgets
            // refreshes and may honour this loosely.
            let quarterHour = Date().addingTimeInterval(15 * 60)
            let midnight = Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) ?? quarterHour

            completion(Timeline(entries: [entry], policy: .after(min(quarterHour, midnight))))
        }
    }

    private func reading() async -> MilesEntry {
        do {
            return MilesEntry(date: Date(), miles: try await DistanceStore.milesToday())
        } catch {
            return MilesEntry(date: Date(), miles: DistanceStore.cachedMiles())
        }
    }
}

// MARK: - View

struct FurlingWidgetView: View {
    var entry: MilesEntry

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Image(systemName: "figure.walk")
        }
        .containerBackground(.clear, for: .widget)
    }

    private var label: String {
        guard let miles = entry.miles else { return "— mi" }
        return DistanceStore.short(miles)
    }
}

// MARK: - Widget

struct FurlingWidget: Widget {
    let kind = "FurlingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MilesProvider()) { entry in
            FurlingWidgetView(entry: entry)
        }
        .configurationDisplayName("Miles Walked")
        .description("Today's distance, beside the date.")
        .supportedFamilies([.accessoryInline])
    }
}

#Preview(as: .accessoryInline) {
    FurlingWidget()
} timeline: {
    MilesEntry(date: Date(), miles: 3.7)
    MilesEntry(date: Date(), miles: 12.4)
    MilesEntry(date: Date(), miles: nil)
}
