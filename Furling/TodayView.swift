//
//  TodayView.swift
//  Furling
//
//  The app exists mainly to hold the HealthKit permission the widget relies
//  on, so it stays deliberately thin: one number, and a way to force a
//  widget refresh.
//

import SwiftUI
import WidgetKit

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var miles: Double?
    @State private var problem: String?

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Text("Today")
                .font(.footnote.weight(.semibold))
                .kerning(1.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(miles.map { String(format: "%.2f", $0) } ?? "—")
                .font(.system(size: 88, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: miles)

            Text("miles walked")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            if let problem {
                Text(problem)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange)
                    .padding(.horizontal)
            }

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

    private func begin() async {
        do {
            try await DistanceStore.requestAuthorization()
        } catch {
            problem = error.localizedDescription
            return
        }
        await load()
    }

    private func load() async {
        do {
            miles = try await DistanceStore.milesToday()
            problem = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // A denied permission surfaces here as a zero-sample read rather
            // than an error, so check Settings > Privacy > Health if this
            // stays at 0.00 after a walk.
            problem = error.localizedDescription
        }
    }
}

#Preview {
    TodayView()
}
