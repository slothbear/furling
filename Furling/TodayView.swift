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

    /// The orange for health errors. System orange is too faint on the soft
    /// orange Halloween background, so light mode gets a burnt orange (about
    /// 4.3:1 against that peach, 5:1 against the usual off-white). Dark mode
    /// keeps the system's bright orange, which a darker one would lose against.
    static let furlingWarning = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemOrange
            : UIColor(red: 0.65, green: 0.245, blue: 0.0, alpha: 1)  // #A63E00
    })
}

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var reading: DistanceStore.Reading = .live(0)
    @State private var yesterday: Double?
    @State private var authProblem: String?
    @State private var showingSettings = false
    @State private var burstStart: Date?
    @State private var screenSize = CGSize.zero
    /// Long-pressing the countdown caption pretends it is 31 October, so
    /// Halloween can be tried out in advance. Left in the shipped app on
    /// purpose, and not announced.
    @State private var previewHalloween = false

    /// Today, unless the caption has been long-pressed.
    private var shownDate: Date {
        if previewHalloween {
            let calendar = Calendar.current
            let year = calendar.component(.year, from: Date())
            return calendar.date(from: DateComponents(year: year, month: 10, day: 31, hour: 12)) ?? Date()
        }
        return Date()
    }

    /// October gets the candy corn and a soft orange background.
    private var isOctober: Bool {
        OctoberOrnament.dayOfOctober(shownDate) != nil
    }

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

            // No unit here — "miles walked" directly above already says it.
            //
            // Zero is hidden as well as nil. HealthKit answers an unauthorised
            // or empty read with "no data", which the query treats as a real
            // zero — correct for today, but for yesterday it can't be told
            // apart from a day you genuinely didn't walk. Rather than assert
            // either, say nothing.
            Group {
                if let yesterday, yesterday > 0 {
                    Text("yesterday " + String(format: "%.2f", yesterday))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                        .padding(.top, 10)
                        .transition(.opacity)
                }
            }
            .animation(.default, value: yesterday)

            Spacer()

            // In the stack rather than floating over it, so the two Spacers
            // share whatever room is left and the number sits clear of the
            // candy corn on any screen size. Present only in October.
            if isOctober {
                OctoberOrnamentView(
                    date: shownDate,
                    burstStart: burstStart,
                    screen: screenSize,
                    onCaptionLongPress: { previewHalloween.toggle() })
                    .padding(.top, 8)
            }

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
        // The confetti spreads itself across this whole view, so it needs this
        // view's size and a coordinate space to locate the candy corn within.
        .coordinateSpace(name: OctoberOrnament.screenSpace)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
        .background(
            (isOctober ? Color.furlingOctoberBackground : Color.furlingBackground)
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            celebrate()
            await begin()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                celebrate()
                Task { await load() }
            }
        }
    }

    /// Each time the app opens on Halloween, set off the burst.
    private func celebrate() {
        if OctoberOrnament.isHalloween(Date()) { burstStart = Date() }
    }

    /// Mirrors the widget's symbol vocabulary, with room here to explain.
    @ViewBuilder
    private var status: some View {
        switch reading {
        case .live:
            if let authProblem {
                Label(authProblem, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(Color.furlingWarning)
            }
        case .stale:
            Label("Showing the last reading from earlier today.",
                  systemImage: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
        case .unavailable:
            Label("Can't read Health data right now. Unlock the phone, or check Settings › Privacy & Security › Health › Furling.",
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(Color.furlingWarning)
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
        yesterday = await DistanceStore.milesYesterday()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    TodayView()
}
