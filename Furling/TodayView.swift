//
//  TodayView.swift
//  Furling
//
//  The app exists mainly to hold the HealthKit permission the widget relies
//  on, so it stays deliberately thin: one number and a note about where that
//  number came from.
//

import SwiftUI
import UIKit
import WidgetKit

extension Color {
    /// Off-white and off-black rather than the system's pure values.
    /// Note this departs from `systemBackground`; on OLED the dark variant
    /// no longer switches pixels fully off.
    static let furlingBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.094, blue: 0.114, alpha: 1)  // #14181D
            : UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1)  // #F3F4F6
    })
}

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var reading: DistanceStore.Reading = .live(0)
    @State private var authProblem: String?
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

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

            Text(buildLabel)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 18)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.furlingBackground.ignoresSafeArea())
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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

    /// Marketing version and build number, e.g. "Furling 1.0, build 2".
    /// The build number is labelled rather than parenthesised so a tester
    /// can find it without knowing the convention.
    private var buildLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Furling \(version), build \(build)"
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
