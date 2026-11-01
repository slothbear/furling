//
//  SettingsView.swift
//  Furling
//
//  Reached from the gear on the main screen. Currently just the symbol
//  legend, but it's the single entry point for anything configurable that
//  arrives later — units, decimal places — so testers only learn one place
//  to look.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private static let repository = URL(string: "https://github.com/slothbear/furling")!

    private let changelog = Changelog.load()

    /// Marketing version and build number, e.g. "Furling 1.0, build 2".
    /// The build number is labelled rather than parenthesised so a tester
    /// can find it without knowing the convention.
    private static var buildLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Furling \(version), build \(build)"
    }

    var body: some View {
        NavigationStack {
            List {
                // Which build this is, at the top where a tester looks first
                // when asked.
                Section {
                    Text(Self.buildLabel)
                        .frame(maxWidth: .infinity)
                }
                .listSectionSpacing(.compact)

                // The symbols with their names only; the full explanations
                // are a tap away, the same way past builds are.
                Section {
                    ForEach(widgetSymbols) { symbol in
                        CompactSymbolRow(symbol: symbol)
                    }
                    NavigationLink("what they mean") {
                        WidgetSymbolsView()
                    }
                } header: {
                    Text("widget symbols")
                }
                // Grouped lists uppercase section headers by default; this
                // keeps "widget symbols" as written.
                .textCase(nil)

                // Only the newest build here; the rest are a tap away, so the
                // screen doesn't grow by a build every few weeks.
                if let latest = changelog.first {
                    Section {
                        ChangelogRow(entry: latest)
                        if changelog.count > 1 {
                            NavigationLink("previously on Furling…") {
                                PreviouslyView(entries: Array(changelog.dropFirst()))
                            }
                        }
                    } header: {
                        Text("new & noteworthy")
                    }
                    .textCase(nil)
                }


                Section {
                    // A Link tints its whole label, which would drag the URL
                    // line blue along with the title. A plain button keeps the
                    // row looking like the legend rows above it.
                    Button {
                        openURL(Self.repository)
                    } label: {
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.title3)
                                .frame(width: 30)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("source on GitHub")
                                    .foregroundStyle(.tint)
                                Text("github.com/slothbear/furling")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("source")
                }
                .textCase(nil)
            }
            .scrollContentBackground(.hidden)
            .background(Color.furlingBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// The widget's three symbols and what each means, shared by the short list
/// in settings and the full explanations behind it.
fileprivate struct WidgetSymbol: Identifiable {
    let symbol: String
    let title: String
    let detail: String
    var id: String { symbol }
}

fileprivate let widgetSymbols: [WidgetSymbol] = [
    WidgetSymbol(
        symbol: "hare",
        title: "live reading",
        detail: "The number is current. It comes from Apple Health, or from iPhone's motion sensor while the phone is locked, which doesn't count walks taken with only an Apple Watch. A zero here means you haven't walked yet today.\n\nLock screen widgets update on iOS's schedule, not Furling's, so the widget can trail a few minutes behind. Opening the app updates it right away. You can tap on the widget to open the app."),
    WidgetSymbol(
        symbol: "clock.arrow.circlepath",
        title: "last known reading",
        detail: "Neither Apple Health nor the motion sensor could be read, so this is the most recent reading from earlier today."),
    WidgetSymbol(
        symbol: "exclamationmark.triangle",
        title: "no reading",
        detail: "Neither Apple Health nor the motion sensor could be read, and there's no earlier reading from today.\n\nApple Health data can't be read until the phone has been unlocked once after a restart.\n\nIf the warning symbol persists, check Settings › Privacy & Security › Health › Furling and make sure Walking + Running Distance is enabled, and that Motion & Fitness is on for Furling."),
]

private struct CompactSymbolRow: View {
    let symbol: WidgetSymbol

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol.symbol)
                .font(.title3)
                .frame(width: 30)
            Text(symbol.title)
        }
    }
}

/// The full explanations, one row per symbol.
private struct WidgetSymbolsView: View {
    var body: some View {
        List {
            Section {
                ForEach(widgetSymbols) { symbol in
                    LegendRow(symbol: symbol.symbol, title: symbol.title, detail: symbol.detail)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.furlingBackground.ignoresSafeArea())
        .navigationTitle("Widget Symbols")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegendRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Every build but the newest, newest first, in the same rows the settings
/// screen uses.
private struct PreviouslyView: View {
    let entries: [ChangelogEntry]

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    ChangelogRow(entry: entry)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.furlingBackground.ignoresSafeArea())
        .navigationTitle("Previously on Furling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ChangelogRow: View {
    let entry: ChangelogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("build \(entry.id)")
                Spacer()
                Text(entry.date, format: .dateTime.day().month().year())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(entry.categories) { category in
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.footnote.weight(.medium))
                    ForEach(category.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                            // Inside an HStack a Text will compress and
                            // truncate before it wraps. fixedSize makes it
                            // claim the height it needs instead, which is
                            // what keeps longer entries readable at larger
                            // Dynamic Type sizes.
                            Text(item)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
