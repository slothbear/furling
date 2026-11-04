//
//  NovemberLeaves.swift
//  Furling
//
//  Leaves falling down the main screen through November: one on the 1st, one
//  more each day, thirty on the 30th. Every fifth one is a rabbit. They fall
//  each time the app opens and settle in a strip of grass along the bottom,
//  where they stay until the app next opens. On Election Day the leaves are
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

    /// The rabbit stands out from the leaves rather than matching them.
    static func rabbit(dark: Bool) -> Color {
        Color(hex: dark ? 0xF1E6D6 : 0x5A3B26)
    }

    /// Dry late-autumn grass. The front fringe is a shade off the back so the
    /// two layers read as depth rather than one flat strip.
    static func grass(front: Bool, dark: Bool) -> Color {
        switch (front, dark) {
        case (false, false): Color(hex: 0x8C9A5B)
        case (true, false):  Color(hex: 0x6E7D42)
        case (false, true):  Color(hex: 0x2E3A1E)
        case (true, true):   Color(hex: 0x3F4D28)
        }
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
        let x: Double          // 0...1 across the width
        let delay: Double      // seconds before it starts falling
        let duration: Double   // seconds to cross the screen
        let size: Double
        let sway: Double       // points either side
        let swayRate: Double
        let spin: Double       // degrees over the whole fall
        let tilt: Double
        let rest: Double       // centre's height above the bottom once landed

        static func make(count: Int, ballot: Bool) -> [Faller] {
            (0..<count).map { index in
                let rabbit = NovemberLeaves.isRabbit(index)
                let ballotLeaf = ballot && !rabbit
                let size: Double = ballotLeaf ? .random(in: 54...66) : .random(in: 24...40)
                let spin: Double = .random(in: -260...260)
                // Rabbits land on their feet and ballot leaves land readable;
                // ordinary leaves come to rest however they happen to fall.
                let landing: Double? = rabbit ? .random(in: -8...8)
                    : ballotLeaf ? .random(in: -20...20) : nil
                let rest: Double = rabbit ? size / 2 + 4
                    : ballotLeaf ? .random(in: 24...34) : .random(in: 6...24)
                return Faller(rabbit: rabbit,
                              ballot: ballotLeaf,
                              kind: LeafKind.allCases.randomElement()!,
                              colorIndex: .random(in: 0..<4),
                              x: .random(in: 0.06...0.94),
                              delay: .random(in: 0...3.5),
                              duration: .random(in: 6...8.5),
                              size: size,
                              sway: .random(in: 14...38),
                              swayRate: .random(in: 0.8...1.6),
                              spin: spin,
                              tilt: landing.map { $0 - spin } ?? .random(in: 0..<360),
                              rest: rest)
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
            ZStack(alignment: .bottom) {
                TimelineView(.animation(paused: finished)) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    ZStack(alignment: .topLeading) {
                        ForEach(fallers.indices, id: \.self) { index in
                            let f = fallers[index]
                            // Clamped at 1: once landed, a leaf stops where it is.
                            let t = min((elapsed - f.delay) / f.duration, 1)
                            if t > 0 {
                                let swayTime = f.delay + f.duration * t
                                let restY = height - f.rest
                                piece(f)
                                    .frame(width: f.size, height: f.size)
                                    .rotationEffect(.degrees(f.tilt + f.spin * t))
                                    .position(
                                        // Kept on screen, so none lands half off the edge.
                                        x: min(max(f.x * width + sin(swayTime * f.swayRate * 2) * f.sway,
                                                   f.size / 2), width - f.size / 2),
                                        y: -f.size + (restY + f.size) * t)
                            }
                        }
                    }
                    .frame(width: width, height: height, alignment: .topLeading)
                }
                // A sparser fringe in front, so the pile sits in the grass
                // rather than on top of it.
                NovemberGrass(layer: .front)
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
            Image(systemName: "hare.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AutumnColor.rabbit(dark: dark))
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

// MARK: - Grass

/// A strip of grass along the bottom edge through November. The back layer
/// sits behind the main screen's content; the front layer is drawn over the
/// fallen leaves so they look tucked in.
struct NovemberGrass: View {
    enum Layer { case back, front }
    var layer: Layer = .back

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let front = layer == .front
        GrassShape(spacing: front ? 11 : 5,
                   heights: front ? 8...20 : 14...36,
                   salt: front ? 7 : 1)
            .fill(AutumnColor.grass(front: front, dark: colorScheme == .dark))
            .frame(height: 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Blades of grass standing on the bottom of the rect. Placement comes from a
/// fixed hash of the blade's index, so the strip looks the same every time.
struct GrassShape: Shape {
    let spacing: Double
    let heights: ClosedRange<Double>
    let salt: Int

    private func noise(_ i: Int, _ k: Int) -> Double {
        let v = sin(Double(i) * 12.9898 + Double(salt * 10 + k) * 78.233) * 43758.5453
        return v - v.rounded(.down)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let base = rect.maxY
        var x = rect.minX - spacing
        var i = 0
        while x < rect.maxX + spacing {
            let h = heights.lowerBound + (heights.upperBound - heights.lowerBound) * noise(i, 0)
            let w = spacing * (1.2 + noise(i, 1))
            let lean = (noise(i, 2) - 0.5) * h * 0.6
            path.move(to: CGPoint(x: x - w / 2, y: base))
            path.addQuadCurve(to: CGPoint(x: x + lean, y: base - h),
                              control: CGPoint(x: x - w / 4 + lean * 0.3, y: base - h * 0.6))
            path.addQuadCurve(to: CGPoint(x: x + w / 2, y: base),
                              control: CGPoint(x: x + w / 4 + lean * 0.3, y: base - h * 0.5))
            path.closeSubpath()
            x += spacing * (0.7 + 0.6 * noise(i, 3))
            i += 1
        }
        // A solid turf line so no background shows between blade roots.
        path.addRect(CGRect(x: rect.minX, y: base - 3, width: rect.width, height: 3))
        return path
    }
}

#Preview("day 30") {
    FallingLeaves(day: 30, start: Date())
        .background {
            Color.furlingNovemberBackground
            NovemberGrass()
        }
}

#Preview("Election Day") {
    FallingLeaves(day: 3, ballot: true, start: Date())
        .background {
            Color.furlingNovemberBackground
            NovemberGrass()
        }
}
