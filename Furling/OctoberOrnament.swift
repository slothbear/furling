//
//  OctoberOrnament.swift
//  Furling
//
//  A candy corn that fills one slice a day through October and bursts into
//  confetti on Halloween. It appears only in October, decided by the date, so
//  nothing has to be removed afterwards — and it comes back next year.
//
//  Kept free of anything from the app target so the test target can compile
//  this file directly.
//

import SwiftUI
import UIKit

extension Color {
    /// A soft orange for the main screen's background all through October.
    /// The cream tip of a candy corn is invisible on the usual off-white, so
    /// the month gets its own ground. Warm and dark in dark mode.
    static let furlingOctoberBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.102, blue: 0.051, alpha: 1)  // #2A1A0D
            : UIColor(red: 0.957, green: 0.827, blue: 0.651, alpha: 1)  // #F4D3A6
    })
}

// MARK: - Dates

enum OctoberOrnament {
    /// One slice per day. October always has 31 of them.
    static let sliceCount = 31

    /// Name of the coordinate space the screen view declares, so the burst can
    /// work out where the wedge sits within it.
    static let screenSpace = "furlingScreen"

    /// How long the confetti takes to fly and fade, in seconds.
    static let burstDuration = 4.4

    /// How long the wedge sits untouched before a small candy corn appears in
    /// it, asking to be touched.
    static let hintDelay = 2.0

    /// 1...31 during October, nil the rest of the year.
    static func dayOfOctober(_ date: Date, calendar: Calendar = .current) -> Int? {
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard parts.month == 10, let day = parts.day else { return nil }
        return day
    }

    /// Zero on Halloween itself.
    static func daysUntilHalloween(_ date: Date, calendar: Calendar = .current) -> Int? {
        dayOfOctober(date, calendar: calendar).map { sliceCount - $0 }
    }

    static func isHalloween(_ date: Date, calendar: Calendar = .current) -> Bool {
        daysUntilHalloween(date, calendar: calendar) == 0
    }

    static func caption(_ date: Date, calendar: Calendar = .current) -> String? {
        guard let days = daysUntilHalloween(date, calendar: calendar) else { return nil }
        switch days {
        case 0: return "happy Halloween"
        case 1: return "1 day to Halloween"
        default: return "\(days) days to Halloween"
        }
    }

    /// 0 yellow base, 1 orange middle, 2 cream tip — thirds, counted from the
    /// bottom, so the tip is the last stretch before Halloween.
    static func band(forSlice index: Int) -> Int {
        min(2, index * 3 / sliceCount)
    }
}

// MARK: - Shape

struct CandyCornShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 100 * rect.width,
                    y: rect.minY + (y - 4) / 144 * rect.height)
        }
        var path = Path()
        path.move(to: point(50, 4))
        path.addCurve(to: point(78, 40), control1: point(62, 4), control2: point(70, 14))
        path.addLine(to: point(96, 120))
        path.addQuadCurve(to: point(90, 144), control: point(100, 136))
        path.addQuadCurve(to: point(72, 148), control: point(84, 148))
        path.addLine(to: point(28, 148))
        path.addQuadCurve(to: point(10, 144), control: point(16, 148))
        path.addQuadCurve(to: point(4, 120), control: point(0, 136))
        path.addLine(to: point(22, 40))
        path.addCurve(to: point(50, 4), control1: point(30, 14), control2: point(38, 4))
        path.closeSubpath()
        return path
    }
}

private enum CandyCornColor {
    static let yellow = Color(red: 0.957, green: 0.769, blue: 0.188)
    static let orange = Color(red: 0.941, green: 0.541, blue: 0.141)
    static let cream = Color(red: 0.969, green: 0.953, blue: 0.910)

    static func band(_ index: Int) -> Color {
        [yellow, orange, cream][index]
    }

    /// The three bands of a small whole candy corn, hard-edged, base first.
    static let stripes = LinearGradient(
        stops: [
            .init(color: yellow, location: 0),
            .init(color: yellow, location: 1 / 3),
            .init(color: orange, location: 1 / 3),
            .init(color: orange, location: 2 / 3),
            .init(color: cream, location: 2 / 3),
            .init(color: cream, location: 1),
        ],
        startPoint: .bottom, endPoint: .top)
}

// MARK: - The countdown

struct CandyCornCountdown: View {
    /// How many slices are filled, counted from the base.
    var litSlices: Int

    var body: some View {
        VStack(spacing: 1) {
            ForEach((0..<OctoberOrnament.sliceCount).reversed(), id: \.self) { slice in
                Rectangle()
                    .fill(slice < litSlices
                          ? CandyCornColor.band(OctoberOrnament.band(forSlice: slice))
                          : Color.primary.opacity(0.07))
            }
        }
        .mask(CandyCornShape())
        .overlay(CandyCornShape().stroke(Color.primary.opacity(0.3), lineWidth: 1.5))
    }
}

struct OctoberOrnamentView: View {
    var date: Date = Date()
    /// Set by the screen when the app opens on Halloween. Touching the wedge
    /// sets off a burst too, on any day in October.
    var burstStart: Date?
    /// The screen view's size; the burst spreads itself across all of it.
    var screen: CGSize = .zero

    /// Called when the caption is long-pressed, so the screen can pretend it
    /// is Halloween and the wedge can be tried out without waiting for the
    /// day. Kept in the shipped app deliberately.
    var onCaptionLongPress: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var touchedAt: Date?
    @State private var hintVisible = false

    /// The wedge only responds, and only asks to be touched, on Halloween.
    private var interactive: Bool {
        OctoberOrnament.isHalloween(date)
    }

    /// Whichever burst started last, from the app opening or from a touch.
    private var activeBurst: Date? {
        [burstStart, touchedAt].compactMap { $0 }.max()
    }

    /// What the hint timer restarts on: a new burst, or the day changing
    /// into or out of Halloween.
    private struct HintTrigger: Equatable {
        var burst: Date?
        var interactive: Bool
    }

    var body: some View {
        if let day = OctoberOrnament.dayOfOctober(date),
           let caption = OctoberOrnament.caption(date) {
            VStack(spacing: 12) {
                CandyCornCountdown(litSlices: day)
                    .frame(width: 118, height: 170)
                    .overlay { hint }
                    .overlay { burst }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if interactive { touchedAt = Date() }
                    }
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .onLongPressGesture { onCaptionLongPress?() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(caption)
            .accessibilityAddTraits(interactive ? .isButton : [])
            .accessibilityHint(interactive ? "Sets off candy corn confetti" : "")
            // Restarts whenever a burst starts, so the hint goes away on a
            // touch and comes back a couple of seconds after the confetti has
            // finished rather than while it is still flying.
            .task(id: HintTrigger(burst: activeBurst, interactive: interactive)) {
                hintVisible = false
                guard interactive else { return }
                let wait = OctoberOrnament.hintDelay
                    + (activeBurst == nil ? 0 : OctoberOrnament.burstDuration)
                do {
                    try await Task.sleep(for: .seconds(wait))
                    hintVisible = true
                } catch {}
            }
        }
    }

    /// A small whole candy corn in the middle of the wedge, pulsing gently.
    /// Only on Halloween, and not with Reduce Motion on, since touching does
    /// nothing then.
    @ViewBuilder
    private var hint: some View {
        if hintVisible, interactive, !reduceMotion {
            PhaseAnimator([false, true]) { grown in
                CandyCornShape()
                    .fill(CandyCornColor.stripes)
                    .overlay(CandyCornShape().stroke(Color.primary.opacity(0.4), lineWidth: 1))
                    .frame(width: 22, height: 32)
                    .scaleEffect(grown ? 1.18 : 0.9)
            } animation: { _ in
                .easeInOut(duration: 0.8)
            }
            .transition(.opacity)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var burst: some View {
        if let activeBurst, !reduceMotion {
            // Keyed on the start time so each new burst is fresh. Without it
            // the first one leaves `finished` set, and every later burst
            // starts paused.
            CandyCornBurst(start: activeBurst, screen: screen)
                .id(activeBurst)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - The burst

private struct CandyCornBurst: View {
    let start: Date
    /// Size of the whole screen view, so the pieces can land anywhere on it.
    let screen: CGSize

    /// Where on the screen a piece is headed, as fractions of its width and
    /// height, plus how it looks on the way.
    private struct Piece {
        let targetX: Double
        let targetY: Double
        let size: Double
        let spin: Double
        let tilt: Double

        /// One piece per cell of a jittered grid, so the screen fills evenly
        /// rather than clumping the way purely random targets do.
        static func grid(columns: Int, rows: Int) -> [Piece] {
            var pieces: [Piece] = []
            for row in 0..<rows {
                for column in 0..<columns {
                    pieces.append(Piece(
                        targetX: (Double(column) + .random(in: 0.1...0.9)) / Double(columns),
                        targetY: (Double(row) + .random(in: 0.1...0.9)) / Double(rows),
                        size: .random(in: 14...26),
                        spin: .random(in: -540...540),
                        tilt: .random(in: 0..<360)))
                }
            }
            return pieces
        }
    }

    private static let duration = OctoberOrnament.burstDuration

    // State rather than a plain property, so a parent re-render cannot roll
    // new random pieces halfway through the burst.
    @State private var pieces = Piece.grid(columns: 6, rows: 8)
    @State private var finished = false
    /// Centre of the wedge in the screen's coordinate space: where it starts.
    @State private var origin = CGPoint.zero

    var body: some View {
        let width = screen.width > 0 ? screen.width : 390
        let height = screen.height > 0 ? screen.height : 844
        TimelineView(.animation(paused: finished)) { context in
            let t = min(1, max(0, context.date.timeIntervalSince(start) / Self.duration))
            let travel = 1 - pow(1 - t, 3)
            // Fully visible for most of the flight, then gone by the end.
            let opacity = t < 0.65 ? 1.0 : max(0, (1 - t) / 0.35)
            ZStack {
                ForEach(pieces.indices, id: \.self) { index in
                    let piece = pieces[index]
                    CandyCornShape()
                        .fill(CandyCornColor.stripes)
                        .frame(width: piece.size, height: piece.size * 1.44)
                        .rotationEffect(.degrees(piece.tilt + piece.spin * t))
                        .offset(x: (piece.targetX * width - origin.x) * travel,
                                y: (piece.targetY * height - origin.y) * travel + 40 * t * t)
                        .opacity(opacity)
                }
            }
        }
        .onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .named(OctoberOrnament.screenSpace))
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { origin = $0 }
        .task {
            try? await Task.sleep(for: .seconds(Self.duration + 0.2))
            finished = true
        }
    }
}

#Preview("day 4") {
    OctoberOrnamentView(date: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 4))!)
}

#Preview("Halloween") {
    OctoberOrnamentView(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 31))!,
        burstStart: Date())
}
