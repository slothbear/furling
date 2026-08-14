//
//  SettingsView.swift
//  Furling
//
//  Created by adam on 8/14/26.
//


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
                        symbol: "figure.walk",
                        title: "Live reading",
                        detail: "The number came straight from Health. A zero here means you haven't walked yet today."
                    )
                    LegendRow(
                        symbol: "clock.arrow.circlepath",
                        title: "Last known reading",
                        detail: "Health couldn't be read, so this is the most recent figure from earlier today."
                    )
                    LegendRow(
                        symbol: "exclamationmark.triangle",
                        title: "No reading",
                        detail: "Health couldn't be read and nothing was stored yet. The zero is a placeholder, not a measurement."
                    )
                } header: {
                    Text("widget symbols")
                } footer: {
                    Text("Health data can't be read until the phone has been unlocked once after a restart. If the warning symbol sticks around, check Settings › Privacy & Security › Health › Furling and make sure Walking + Running Distance is switched on.")
                }
                // Grouped lists uppercase section headers by default; this
                // keeps "widget symbols" as written.
                .textCase(nil)
            }
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
