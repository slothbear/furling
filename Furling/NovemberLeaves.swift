//
//  NovemberLeaves.swift
//  Furling
//
//  Leaves falling down the main screen through November: one on the 1st, one
//  more each day, thirty on the 30th. Every fifth one is a rabbit. They fall
//  each time the app opens and pile up on a photo of a hedge along the
//  bottom, where they stay until the app next opens. On Election Day the leaves are
//  ballot leaves that say VOTE. November only, decided by the date, so
//  nothing needs removing and it returns every year.
//
//  Kept free of anything from the app target so the test target can compile
//  this file directly.
//

import SwiftUI
import UIKit

extension Color {
    /// The main screen's background through November: muted wheat in light
    /// mode, deep rust in dark.
    static let furlingNovemberBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.231, green: 0.133, blue: 0.098, alpha: 1)  // #3B2219
            : UIColor(red: 0.914, green: 0.863, blue: 0.753, alpha: 1)  // #E9DCC0
    })
}

// MARK: - Dates

enum NovemberLeaves {
    /// 1...30 during November, nil the rest of the year.
    static func dayOfNovember(_ date: Date, calendar: Calendar = .current) -> Int? {
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard parts.month == 11, let day = parts.day else { return nil }
        return day
    }

    /// One more each day: one on the 1st, thirty on the 30th.
    static func fallerCount(onDay day: Int) -> Int { day }

    /// Every fifth faller is a rabbit, counting from the first: the one added
    /// on day 5, day 10, and so on. `index` is zero-based.
    static func isRabbit(_ index: Int) -> Bool { (index + 1) % 5 == 0 }

    static func rabbitCount(onDay day: Int) -> Int { day / 5 }

    /// US Election Day: the Tuesday after the first Monday in November, so
    /// anywhere from the 2nd to the 8th. It falls on 3 November in 2026.
    static func isElectionDay(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.month, .day, .weekday], from: date)
        guard parts.month == 11, parts.weekday == 3, let day = parts.day else { return false }
        return (2...8).contains(day)
    }
}

// MARK: - Leaf shapes

/// The four leaves, drawn in a 100 × 100 box with the stem at the bottom.
enum LeafKind: CaseIterable {
    case maple, oak, birch, elm

    fileprivate var outline: String {
        switch self {
        case .maple:
            "M50 5 L56 22 L66 16 L63 33 L80 26 L74 42 L92 46 L76 56 L80 64 L62 62 L60 72 L52 66 L52 92 L48 92 L48 66 L40 72 L38 62 L20 64 L24 56 L8 46 L26 42 L20 26 L37 33 L34 16 L44 22 Z"
        case .oak:
            "M50 4 C57 4 59 10 56 15 C64 12 70 18 64 25 C60 28 58 28 58 30 C68 28 74 36 66 42 C62 45 60 45 60 46 C70 46 74 55 65 59 C62 61 60 61 60 62 C68 64 66 74 57 72 C60 78 56 84 52 80 L52 94 L48 94 L48 80 C44 84 40 78 43 72 C34 74 32 64 40 62 C40 61 38 61 35 59 C26 55 30 46 40 46 C40 45 38 45 34 42 C26 36 32 28 42 30 C42 28 40 28 36 25 C30 18 36 12 44 15 C41 10 43 4 50 4 Z"
        case .birch:
            "M50 6 C70 20 74 52 52 82 L52 94 L48 94 L48 82 C26 52 30 20 50 6 Z"
        case .elm:
            "M48 8 L54 14 L58 13 L60 20 L64 21 L65 29 L68 32 L67 40 L70 44 L67 52 L68 58 L63 64 L62 70 L56 75 L52 82 L52 94 L48 94 L48 82 L42 76 L38 70 L33 66 L33 58 L30 52 L32 44 L30 38 L34 32 L34 25 L39 22 L41 15 Z"
        }
    }

    fileprivate var veins: String {
        switch self {
        case .maple: "M50 90 L50 24 M50 60 L26 44 M50 60 L74 44 M50 70 L32 64 M50 70 L68 64"
        case .oak:   "M50 90 L50 14 M50 30 L60 24 M50 44 L64 40 M50 58 L62 58 M50 30 L40 24 M50 44 L36 40 M50 58 L38 58"
        case .birch: "M50 90 L50 14 M50 30 L62 24 M50 44 L66 38 M50 58 L64 54 M50 30 L38 24 M50 44 L34 38 M50 58 L36 54"
        case .elm:   "M50 90 L49 14 M50 26 L60 20 M50 38 L65 32 M50 50 L66 46 M50 62 L62 62 M49 26 L40 21 M49 38 L33 33 M50 50 L32 48 M50 62 L36 62"
        }
    }

    /// How wide the leaf is across its middle, as a share of its box. Its
    /// length, tip to stem, is about 0.89 of the box for all four.
    fileprivate var breadth: Double {
        switch self {
        case .maple: 0.84
        case .oak:   0.48
        case .birch, .elm: 0.40
        }
    }

    /// A broad, plain leaf for Election Day — wide enough in the middle to
    /// carry a word, with no veins to fight it.
    fileprivate static let ballotOutline =
        "M50 8 C78 18 92 46 76 68 C68 78 57 82 52 84 L52 94 L48 94 L48 84 C43 82 32 78 24 68 C8 46 22 18 50 8 Z"
}

/// A path given in the SVG subset the leaves use — absolute M, L, C and Z —
/// parsed once and scaled into whatever rect it is drawn in.
struct LeafPathShape: Shape {
    private let ops: [Op]

    init(_ data: String) { ops = Self.parse(data) }

    private enum Op {
        case move(CGPoint), line(CGPoint), curve(CGPoint, CGPoint, CGPoint), close
    }

    func path(in rect: CGRect) -> Path {
        func p(_ point: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + point.x / 100 * rect.width,
                    y: rect.minY + point.y / 100 * rect.height)
        }
        var path = Path()
        for op in ops {
            switch op {
            case .move(let a): path.move(to: p(a))
            case .line(let a): path.addLine(to: p(a))
            case .curve(let c1, let c2, let a): path.addCurve(to: p(a), control1: p(c1), control2: p(c2))
            case .close: path.closeSubpath()
            }
        }
        return path
    }

    private static func parse(_ data: String) -> [Op] {
        var tokens: [String] = []
        var number = ""
        for ch in data {
            if ch.isLetter {
                if !number.isEmpty { tokens.append(number); number = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," {
                if !number.isEmpty { tokens.append(number); number = "" }
            } else {
                number.append(ch)
            }
        }
        if !number.isEmpty { tokens.append(number) }

        var ops: [Op] = []
        var i = 0
        var command = "M"
        func next() -> CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i]) ?? 0) }
        func point() -> CGPoint { CGPoint(x: next(), y: next()) }
        while i < tokens.count {
            if let letter = tokens[i].first, letter.isLetter {
                command = tokens[i]
                i += 1
                if command == "Z" { ops.append(.close); continue }
            }
            switch command {
            case "M": ops.append(.move(point())); command = "L"
            case "L": ops.append(.line(point()))
            case "C": ops.append(.curve(point(), point(), point()))
            default: i += 1
            }
        }
        return ops
    }
}

private enum AutumnColor {
    static func leaf(_ index: Int, dark: Bool) -> Color {
        let light: [UInt32] = [0xB5442A, 0xD2691E, 0xB8860B, 0x7A4B2A]
        let night: [UInt32] = [0xD9573A, 0xE8893A, 0xE3B23C, 0xC49A6C]
        return Color(hex: (dark ? night : light)[index % 4])
    }

    /// Rabbits come in the leaf colours, or white: indexes 0–3 are the
    /// leaves', 4 and 5 white, so about one rabbit in three is white.
    static let rabbitColors = 6

    static func rabbit(_ index: Int, dark: Bool) -> Color {
        index < 4 ? leaf(index, dark: dark) : Color(hex: dark ? 0xF4EEE4 : 0xFFFBF2)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255)
    }
}

// MARK: - Falling

struct FallingLeaves: View {
    let day: Int
    /// Election Day: the leaves become ballot leaves that say VOTE.
    var ballot = false
    let start: Date

    @Environment(\.colorScheme) private var colorScheme
    @State private var fallers: [Faller] = []
    @State private var finished = false

    fileprivate struct Faller {
        let rabbit: Bool
        let ballot: Bool
        let kind: LeafKind
        let colorIndex: Int
        let filled: Bool       // rabbits only: hare.fill rather than hare
        let x: Double          // 0...1 across the width
        let delay: Double      // seconds before it starts falling
        let duration: Double   // seconds to cross the screen
        let size: Double
        let sway: Double       // points either side
        let swayRate: Double
        let spin: Double       // degrees over the whole fall
        let tilt: Double
        let landing: Double    // degrees it comes to rest at; 0 is stem down
        let nestle: Double     // how far it may sink onto a leaf below, as a share of its height

        var lands: Double { delay + duration }

        /// Across the screen at `time` seconds, kept on screen so none lands
        /// half off the edge.
        func left(at time: Double, width: Double) -> Double {
            min(max(x * width + sin(time * swayRate * 2) * sway, size / 2), width - size / 2)
        }

        /// The piece inside its square box, upright: its width and height
        /// as shares of the box.
        private var shape: (wide: Double, tall: Double) {
            if rabbit { return (1, 0.8) }          // hare is wider than tall
            if ballot { return (0.84, 0.86) }
            return (kind.breadth, 0.89)
        }

        /// Half the width and half the height it covers once landed, with
        /// its turn taken into account.
        var landed: (half: Double, rise: Double) {
            let a = landing * .pi / 180
            let w = shape.wide * size, h = shape.tall * size
            return ((w * abs(cos(a)) + h * abs(sin(a))) / 2,
                    (h * abs(cos(a)) + w * abs(sin(a))) / 2)
        }

        static func make(count: Int, ballot: Bool) -> [Faller] {
            (0..<count).map { index in
                let rabbit = NovemberLeaves.isRabbit(index)
                let ballotLeaf = ballot && !rabbit
                let size: Double = ballotLeaf ? .random(in: 54...66) : .random(in: 24...40)
                let spin: Double = .random(in: -260...260)
                // Rabbits tumble in any way up, and ballot leaves land
                // readable. Ordinary leaves come to rest lying on their side,
                // stem to the left or right, never stood on end.
                let landing: Double = rabbit ? .random(in: 0..<360)
                    : ballotLeaf ? .random(in: -20...20)
                    : (Bool.random() ? 90 : -90) + .random(in: -22...22)
                let colorIndex = Int.random(in: 0..<(rabbit ? AutumnColor.rabbitColors : 4))
                return Faller(rabbit: rabbit,
                              ballot: ballotLeaf,
                              kind: LeafKind.allCases.randomElement()!,
                              colorIndex: colorIndex,
                              // A white outline is too faint on the wheat
                              // background, so white rabbits are always filled.
                              filled: colorIndex >= 4 || .random(),
                              x: .random(in: 0.06...0.94),
                              delay: .random(in: 0...3.5),
                              duration: .random(in: 6...8.5),
                              size: size,
                              sway: .random(in: 14...38),
                              swayRate: .random(in: 0.8...1.6),
                              spin: spin,
                              tilt: landing - spin,
                              landing: landing,
                              nestle: .random(in: 0.25...0.4))
            }
            // In landing order, so each one is drawn over those it lands on.
            .sorted { $0.lands < $1.lands }
        }

        /// Where each one comes to rest: how far it slips sideways at the end
        /// of its fall, and its centre's height above the bottom of the
        /// screen. Taken in landing order, each settles on whatever is
        /// highest beneath it — the hedge, or leaves already down — and slips
        /// a little to the lower side if that is close by, the way a leaf
        /// slides off a heap rather than balancing on its top. It sinks a
        /// little into the hedge, and part way onto a leaf, but never so far
        /// that it hides the one below.
        static func rests(_ fallers: [Faller], width: Double) -> [(slip: Double, height: Double)] {
            let step = 2.0
            let columns = Int(width / step) + 1
            let hedge = (0..<columns).map { NovemberHedge.surface(atX: Double($0) * step, width: width) }
            var pile = [Double](repeating: 0, count: columns)
            func column(_ x: Double) -> Int { min(max(Int(x / step), 0), columns - 1) }

            return fallers.map { f in
                let (half, rise) = f.landed
                let height = rise * 2
                let falls = f.left(at: f.lands, width: width)
                // The tips hang over whatever holds the leaf up, so only the
                // middle of its span has to find support.
                func bottom(at centre: Double) -> Double {
                    var b = 0.0
                    for c in column(centre - half * 0.6)...column(centre + half * 0.6) {
                        b = max(b, hedge[c] - height * 0.15, pile[c] - height * f.nestle)
                    }
                    return b
                }
                var best = (centre: falls, bottom: bottom(at: falls), score: Double.infinity)
                let range = f.size * 0.9
                for d in stride(from: -range, through: range, by: step) {
                    let centre = min(max(falls + d, half), width - half)
                    let b = bottom(at: centre)
                    let score = b + abs(d) * 0.2
                    if score < best.score { best = (centre, b, score) }
                }
                // Its top is a low hump: full height in the middle, falling
                // away towards the tips.
                for c in column(best.centre - half)...column(best.centre + half) {
                    let dx = (Double(c) * step - best.centre) / half
                    pile[c] = max(pile[c], best.bottom + height * (1 - 0.6 * dx * dx))
                }
                return (best.centre - falls, best.bottom + rise)
            }
        }
    }

    /// Long enough for the slowest, latest leaf to land. After that the
    /// timeline pauses and the pile stays as it lies.
    private static let total = 3.5 + 8.5 + 0.3

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let rests = Faller.rests(fallers, width: width)
            TimelineView(.animation(paused: finished)) { context in
                let elapsed = context.date.timeIntervalSince(start)
                ZStack(alignment: .topLeading) {
                    ForEach(fallers.indices, id: \.self) { index in
                        let f = fallers[index]
                        // Clamped at 1: once landed, a leaf stops where it is.
                        let t = min((elapsed - f.delay) / f.duration, 1)
                        if t > 0 {
                            let restY = height - rests[index].height
                            // The slip happens over the last tenth of the fall.
                            let slip = rests[index].slip * min(max((t - 0.9) / 0.1, 0), 1)
                            piece(f)
                                .frame(width: f.size, height: f.size)
                                .rotationEffect(.degrees(f.tilt + f.spin * t))
                                .position(x: f.left(at: f.delay + f.duration * t, width: width) + slip,
                                          y: -f.size + (restY + f.size) * t)
                        }
                    }
                }
                .frame(width: width, height: height, alignment: .topLeading)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            fallers = Faller.make(count: NovemberLeaves.fallerCount(onDay: day), ballot: ballot)
        }
        .task {
            try? await Task.sleep(for: .seconds(Self.total))
            finished = true
        }
    }

    @ViewBuilder
    private func piece(_ f: Faller) -> some View {
        let dark = colorScheme == .dark
        if f.rabbit {
            Image(systemName: f.filled ? "hare.fill" : "hare")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AutumnColor.rabbit(f.colorIndex, dark: dark))
        } else if f.ballot {
            LeafPathShape(LeafKind.ballotOutline)
                .fill(AutumnColor.leaf(f.colorIndex, dark: dark))
                .overlay {
                    Text("VOTE")
                        .font(.system(size: f.size * 0.2, weight: .heavy, design: .rounded))
                        .kerning(0.5)
                        .foregroundStyle(Color(hex: 0xFFF6E6))
                        .offset(y: -f.size * 0.04)
                }
        } else {
            LeafPathShape(f.kind.outline)
                .fill(AutumnColor.leaf(f.colorIndex, dark: dark))
                .overlay(
                    LeafPathShape(f.kind.veins)
                        .stroke(Color.black.opacity(0.28),
                                style: StrokeStyle(lineWidth: f.size / 40, lineCap: .round)))
        }
    }
}

// MARK: - Hedge

/// A photo of a hedge with leaves caught in it, along the bottom edge through
/// November. It sits behind the main screen's content, cut along the top of
/// the greenery so the background shows above it, and the falling leaves pile
/// on that edge.
struct NovemberHedge: View {
    /// The strip's height, measured up from the very bottom of the screen.
    static let height: CGFloat = 130

    /// The photo's width over its height (2000 × 496).
    private static let aspect = 2000.0 / 496.0

    /// The top of the greenery, as a fraction of the photo's height down from
    /// its top, at 51 even steps across its width. Traced from the photo
    /// itself and smoothed, so sprigs poking above the line are trimmed.
    private static let edge: [Double] = [
        0.32, 0.32, 0.31, 0.30, 0.28, 0.26, 0.25, 0.25, 0.25, 0.25,
        0.25, 0.25, 0.25, 0.26, 0.27, 0.27, 0.27, 0.28, 0.29, 0.30,
        0.31, 0.33, 0.35, 0.36, 0.36, 0.36, 0.36, 0.36, 0.35, 0.34,
        0.33, 0.33, 0.33, 0.34, 0.35, 0.37, 0.38, 0.38, 0.39, 0.40,
        0.41, 0.41, 0.41, 0.43, 0.44, 0.47, 0.49, 0.51, 0.52, 0.53,
        0.54,
    ]

    /// Where the photo lands when it fills a strip `width` wide: its drawn
    /// size and its offset from the strip's top-left, centred either way.
    private static func fit(width: CGFloat) -> (size: CGSize, origin: CGPoint) {
        let scale = max(width / aspect, height)
        let size = CGSize(width: scale * aspect, height: scale)
        return (size, CGPoint(x: (width - size.width) / 2, y: (height - size.height) / 2))
    }

    /// The top of the greenery at `x`, in points above the bottom of the
    /// screen, on a screen `width` wide.
    static func surface(atX x: CGFloat, width: CGFloat) -> CGFloat {
        let (size, origin) = fit(width: width)
        let u = min(max((x - origin.x) / size.width, 0), 1) * Double(edge.count - 1)
        let i = min(Int(u), edge.count - 2)
        let v = edge[i] + (edge[i + 1] - edge[i]) * (u - Double(i))
        return height - (origin.y + v * size.height)
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            Image("NovemberHedge")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: Self.height)
                // A daylight photo glares on the rust background; dim it
                // to sit with the night.
                .overlay(Color.black.opacity(colorScheme == .dark ? 0.35 : 0))
                .mask {
                    HedgeTop(width: width).blur(radius: 1.5)
                }
                .clipped()
        }
        .frame(height: Self.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Everything below the greenery's top edge.
    private struct HedgeTop: Shape {
        let width: CGFloat

        func path(in rect: CGRect) -> Path {
            var path = Path()
            // Run past the sides and bottom, so the blur softens only the top.
            path.move(to: CGPoint(x: rect.minX - 8, y: rect.maxY + 8))
            path.addLine(to: CGPoint(x: rect.minX - 8,
                                     y: rect.maxY - NovemberHedge.surface(atX: 0, width: width)))
            for x in stride(from: 0, through: width, by: 4) {
                path.addLine(to: CGPoint(x: rect.minX + x,
                                         y: rect.maxY - NovemberHedge.surface(atX: x, width: width)))
            }
            path.addLine(to: CGPoint(x: rect.minX + width,
                                     y: rect.maxY - NovemberHedge.surface(atX: width, width: width)))
            path.addLine(to: CGPoint(x: rect.minX + width + 8,
                                     y: rect.maxY - NovemberHedge.surface(atX: width, width: width)))
            path.addLine(to: CGPoint(x: rect.minX + width + 8, y: rect.maxY + 8))
            path.closeSubpath()
            return path
        }
    }
}

#Preview("day 30") {
    FallingLeaves(day: 30, start: Date())
        .background {
            Color.furlingNovemberBackground
            NovemberHedge()
        }
}

#Preview("Election Day") {
    FallingLeaves(day: 3, ballot: true, start: Date())
        .background {
            Color.furlingNovemberBackground
            NovemberHedge()
        }
}
