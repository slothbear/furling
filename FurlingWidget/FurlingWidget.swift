//
//  FurlingWidget.swift
//  FurlingWidget
//
//  .accessoryInline is the strip beside the lock screen date. It gets one
//  line, the system font, one optional SF Symbol, and a single tint colour
//  applied by the OS. Anything else you set here is discarded, so the symbol
//  is the only place state can be signalled without spending width.
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct MilesEntry: TimelineEntry {
    let date: Date
    let reading: DistanceStore.Reading
}

// MARK: - Provider

struct MilesProvider: TimelineProvider {

    func placeholder(in context: Context) -> MilesEntry {
        MilesEntry(date: Date(), reading: .live(3.7))
    }

    func getSnapshot(in context: Context, completion: @escaping (MilesEntry) -> Void) {
        // The widget gallery renders a snapshot; querying Health there is
        // slow and may be unauthorized, so show a representative value.
        if context.isPreview {
            completion(MilesEntry(date: Date(), reading: .live(3.7)))
            return
        }
        Task { completion(MilesEntry(date: Date(), reading: await DistanceStore.reading())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MilesEntry>) -> Void) {
        Task {
            let entry = MilesEntry(date: Date(), reading: await DistanceStore.reading())

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
}

// MARK: - View

struct FurlingWidgetView: View {
    var entry: MilesEntry

    var body: some View {
        Label {
            Text(DistanceStore.short(entry.reading.miles))
        } icon: {
            Image(systemName: symbol)
        }
        .containerBackground(.clear, for: .widget)
    }

    /// The number is always real-looking, so the symbol says how much to
    /// trust it: hare for a live reading, a clock for a cached one,
    /// a warning triangle when the zero is a placeholder rather than a fact.
    private var symbol: String {
        switch entry.reading {
        case .live:        return "hare"
        case .stale:       return "clock.arrow.circlepath"
        case .unavailable: return "exclamationmark.triangle"
        }
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

#Preview("Timeline", as: .accessoryInline) {
    FurlingWidget()
} timeline: {
    MilesEntry(date: Date(), reading: .live(3.7))
    MilesEntry(date: Date(), reading: .live(0))
    MilesEntry(date: Date(), reading: .stale(2.1))
    MilesEntry(date: Date(), reading: .unavailable)
}

// All four states at once, for comparing symbol widths side by side.
// This is plain SwiftUI rather than a real widget, so the lock screen's
// monochrome tint, vibrancy, and truncation aren't applied — use the
// Timeline preview above to check those.
#Preview("All states") {
    VStack(alignment: .leading, spacing: 18) {
        FurlingWidgetView(entry: MilesEntry(date: Date(), reading: .live(3.7)))
        FurlingWidgetView(entry: MilesEntry(date: Date(), reading: .live(0)))
        FurlingWidgetView(entry: MilesEntry(date: Date(), reading: .stale(2.1)))
        FurlingWidgetView(entry: MilesEntry(date: Date(), reading: .unavailable))
    }
    .font(.system(size: 17, weight: .medium))
    .foregroundStyle(.white)
    .padding(28)
    .background(Color.black)
}
