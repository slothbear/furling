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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LegendRow(
                        symbol: "hare",
                        title: "Live reading",
                        detail: "The number came straight from Apple Health. A zero here means you haven't walked yet today.\n\nLock screen widgets update on iOS's schedule, not Furling's, so the widget can trail a few minutes behind. Opening the app updates it right away. You can tap on the widget to open the app."
                    )
                    LegendRow(
                        symbol: "clock.arrow.circlepath",
                        title: "Last known reading",
                        detail: "Apple Health couldn't be read, so this is the most recent figure from earlier today."
                    )
                    LegendRow(
                        symbol: "exclamationmark.triangle",
                        title: "No reading",
                        detail: "Apple Health couldn't be read and nothing was stored yet. The zero is a placeholder, not a measurement."
                    )
                } header: {
                    Text("widget symbols")
                } footer: {
                    Text("Apple Health data can't be read until the phone has been unlocked once after a restart. If the warning symbol sticks around, check Settings › Privacy & Security › Health › Furling and make sure Walking + Running Distance is switched on.")
                        .padding(.top, 12)
                }
                // Grouped lists uppercase section headers by default; this
                // keeps "widget symbols" as written.
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

#Preview {
    SettingsView()
}
