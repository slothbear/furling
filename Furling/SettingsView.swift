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
                        title: "live reading",
                        detail: "The number came from Apple Health. A zero here means you haven't walked yet today.\n\nLock screen widgets update on iOS's schedule, not Furling's, so the widget can trail a few minutes behind. Opening the app updates it right away. You can tap on the widget to open the app."
                    )
                    LegendRow(
                        symbol: "clock.arrow.circlepath",
                        title: "last known reading",
                        detail: "Apple Health couldn't be read, so this is the most recent reading from earlier today."
                    )
                    LegendRow(
                        symbol: "exclamationmark.triangle",
                        title: "no reading",
                        detail: "Apple Health returned an error. \n\nApple Health data can't be read until the phone has been unlocked once after a restart.\n\nIf the warning symbol persists, check Settings › Privacy & Security › Health › Furling and make sure Walking + Running Distance is enabled."
                    )
                } header: {
                    Text("widget symbols")
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
