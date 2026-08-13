//
//  TodayView.swift
//  Furling
//
//  The app exists mainly to hold the HealthKit permission the widget relies
//  on, so it stays deliberately thin: one number, a note about where that
//  number came from, and a way to force a widget refresh.
//

import SwiftUI
import WidgetKit

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var reading: DistanceStore.Reading = .live(0)
    @State private var authProblem: String?

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Text("Today")
                .font(.footnote.weight(.semibold))
                .kerning(1.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(String(format: "%.2f", reading.miles))
                .font(.system(size: 88, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: reading)

            Text("miles walked")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            status
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .frame(minHeight: 40)

            Button("Refresh") {
                Task { await load() }
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 32)
        }
        .task { await begin() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await load() } }
        }
    }

    /// Mirrors the widget's symbol vocabulary, with room here to explain.
    @ViewBuilder
    private var status: some View {
        switch reading {
        case .live:
            if let authProblem {
                Label(authProblem, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        case .stale:
            Label("Showing the last reading from earlier today.",
                  systemImage: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
        case .unavailable:
            Label("Can't read Health data right now. Unlock the phone, or check Settings › Privacy & Security › Health › Furling.",
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }

    private func begin() async {
        do {
            try await DistanceStore.requestAuthorization()
        } catch {
            authProblem = error.localizedDescription
        }
        await load()
    }

    private func load() async {
        reading = await DistanceStore.reading()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    TodayView()
}
