//
//  NovemberLeaves.swift
//  Furling
//
//  Leaves falling down the main screen through November: one on the 1st, one
//  more each day, thirty on the 30th. Every fifth one is a rabbit. They fall
//  each time the app opens and pile up on a photo of a hedge along the
//  bottom, where they stay until the app leaves the foreground. A paper
//  leaf bag in the middle counts them in as they land. On Election Day the
//  leaves are ballot leaves that say VOTE; on Thanksgiving the rabbits are
//  turkeys, and on Black Friday shipping boxes. November only, decided by
//  the date, so nothing needs removing and it returns every year.
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

    /// US Thanksgiving: the fourth Thursday in November, so anywhere from
    /// the 22nd to the 28th. It falls on 26 November in 2026.
    static func isThanksgiving(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.month, .day, .weekday], from: date)
        guard parts.month == 11, parts.weekday == 5, let day = parts.day else { return false }
        return (22...28).contains(day)
    }

    /// Black Friday: the day after Thanksgiving, so anywhere from the 23rd
    /// to the 29th. It falls on 27 November in 2026.
    static func isBlackFriday(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.month, .day, .weekday], from: date)
        guard parts.month == 11, parts.weekday == 6, let day = parts.day else { return false }
        return (23...29).contains(day)
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
    /// Thanksgiving: the rabbits become turkeys.
    var thanksgiving = false
    /// Black Friday: the rabbits become shipping boxes.
    var blackFriday = false
    /// Reduce Motion: nothing falls, and the leaf bag starts full.
    var still = false
    let start: Date

    @Environment(\.colorScheme) private var colorScheme
    @State private var fallers: [Faller] = []
    @State private var finished = false
    /// The 30th only: what the full bag throws out once it overflows.
    @State private var spray: [Spray] = []

    /// A leaf or rabbit thrown out of the full bag on the 30th: up out of
    /// its mouth and away to one side, falling off the bottom of the screen.
    fileprivate struct Spray {
        let piece: Faller
        let start: Double     // seconds into the spray
        let across: Double    // where in the mouth it leaves from, in points off centre
        let speed: Double     // sideways, points a second; negative is left
        let rise: Double      // upwards at the start, points a second
        let spinRate: Double  // degrees a second

        static let gravity = 600.0   // points a second, squared

        static func make() -> [Spray] {
            let count = 70
            // Faller.make gives the mix of leaves and every-fifth rabbits,
            // with their shapes, colours and sizes; the motion here replaces
            // the falling it plans.
            return Faller.make(count: count, ballot: false, thanksgiving: false, blackFriday: false)
                .enumerated().map { i, piece in
                    Spray(piece: piece,
                          start: Double(i) / Double(count) * Bag.sprayTime + .random(in: 0...0.1),
                          across: .random(in: -14...14),
                          speed: (Bool.random() ? 1 : -1) * .random(in: 60...200),
                          rise: .random(in: 260...460),
                          spinRate: .random(in: -400...400))
                }
        }
    }

    fileprivate struct Faller {
        let rabbit: Bool       // every fifth: an animal rather than a leaf
        let standIn: StandIn   // what the animal is drawn as
        let ballot: Bool
        let kind: LeafKind
        let colorIndex: Int
        let filled: Bool       // animals only: the filled version rather than the outline
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
            if rabbit {
                switch standIn {
                case .hare: return (1, 0.8)        // hare is wider than tall
                case .turkey: return (0.92, 0.80)
                case .shippingBox: return (0.84, 0.64)
                }
            }
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

        static func make(count: Int, ballot: Bool, thanksgiving: Bool, blackFriday: Bool) -> [Faller] {
            (0..<count).map { index in
                let rabbit = NovemberLeaves.isRabbit(index)
                let ballotLeaf = ballot && !rabbit
                let standIn: StandIn = thanksgiving ? .turkey
                    : blackFriday ? .shippingBox
                    : .hare
                // Turkeys and boxes run half as big again as rabbits: the
                // turkey for its detail (and appetite), the box so its smile
                // reads.
                let size: Double = ballotLeaf ? .random(in: 54...66)
                    : rabbit && standIn != .hare ? .random(in: 36...60)
                    : .random(in: 24...40)
                let spin: Double = .random(in: -260...260)
                // Rabbits tumble on the way down but land on their feet, level,
                // and ballot leaves land readable. Ordinary leaves come to rest
                // lying on their side, stem to the left or right, never stood
                // on end.
                let landing: Double = rabbit ? 0
                    : ballotLeaf ? .random(in: -20...20)
                    : (Bool.random() ? 90 : -90) + .random(in: -22...22)
                // Boxes are always cardboard: the brown leaf colour.
                let colorIndex = rabbit && standIn == .shippingBox ? 3 : Int.random(in: 0..<4)
                return Faller(rabbit: rabbit,
                              standIn: standIn,
                              ballot: ballotLeaf,
                              kind: LeafKind.allCases.randomElement()!,
                              colorIndex: colorIndex,
                              filled: .random(),
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

        /// Where a faller comes to rest, and whether it bounced off the bag
        /// on the way.
        struct Rest {
            /// How far it slips sideways at the end of its fall.
            var slip: Double
            /// Its centre's height above the bottom of the screen.
            var height: Double
            /// When (as a share of its fall) and where across it hit the
            /// bag, if it did. From there it hops clear to its resting place.
            var bounce: (t: Double, x: Double)?
        }

        /// Where each one comes to rest. Taken in landing order, each settles
        /// on whatever is highest beneath it — the hedge, or leaves already
        /// down — and slips a little to the lower side if that is close by,
        /// the way a leaf slides off a heap rather than balancing on its top.
        /// It sinks a little into the hedge, and part way onto a leaf, but
        /// never so far that it hides the one below.
        ///
        /// None comes to rest behind the leaf bag. One whose fall would
        /// carry it into the bag bounces off instead, to whichever side is
        /// nearer, unless that side has already piled up well above the
        /// other.
        static func rests(_ fallers: [Faller], width: Double, height screen: Double) -> [Rest] {
            let step = 2.0
            let columns = Int(width / step) + 1
            let hedge = (0..<columns).map { NovemberHedge.surface(atX: Double($0) * step, width: width) }
            var pile = [Double](repeating: 0, count: columns)
            func column(_ x: Double) -> Int { min(max(Int(x / step), 0), columns - 1) }

            let bagLeft = (width - Bag.width) / 2
            let bagRight = (width + Bag.width) / 2
            // The top of the cuff, in points down from the top of the screen.
            let bagTop = screen - Bag.bottom - Bag.height * 0.94

            return fallers.map { f in
                let (half, rise) = f.landed
                let tall = rise * 2
                let falls = f.left(at: f.lands, width: width)
                // The tips hang over whatever holds the leaf up, so only the
                // middle of its span has to find support.
                func bottom(at centre: Double) -> Double {
                    var b = 0.0
                    for c in column(centre - half * 0.6)...column(centre + half * 0.6) {
                        b = max(b, hedge[c] - tall * 0.15, pile[c] - tall * f.nestle)
                    }
                    return b
                }

                enum Side { case left, right }
                /// The best spot near `base` that is clear of the bag, and on
                /// `side` of it if given. A bounced one looks further afield,
                /// so they roll down the heap beside the bag rather than
                /// stacking against it.
                func settle(near base: Double, side: Side?) -> (centre: Double, bottom: Double) {
                    func clear(_ c: Double) -> Bool {
                        let isLeft = c + half <= bagLeft - 1, isRight = c - half >= bagRight + 1
                        switch side {
                        case .left: return isLeft
                        case .right: return isRight
                        case nil: return isLeft || isRight
                        }
                    }
                    var best: (centre: Double, bottom: Double, score: Double)?
                    let range = f.size * (side == nil ? 0.9 : 2.5)
                    for d in stride(from: -range, through: range, by: step) {
                        let centre = min(max(base + d, half), width - half)
                        guard clear(centre) else { continue }
                        let b = bottom(at: centre)
                        let score = b + abs(d) * 0.2
                        if score < best?.score ?? .infinity { best = (centre, b, score) }
                    }
                    if let best { return (best.centre, best.bottom) }
                    let centre = side == .right ? width - half : min(base, bagLeft - 1 - half)
                    return (centre, bottom(at: centre))
                }

                /// The first moment its fall overlaps the bag — its lower
                /// edge below the bag's top, and the two overlapping across.
                func entry(restY: Double) -> (t: Double, x: Double)? {
                    let reach = f.size * 0.45
                    for i in 0..<200 {
                        let t = Double(i) / 200
                        let y = -f.size + (restY + f.size) * t
                        guard y + reach >= bagTop else { continue }
                        let x = f.left(at: f.delay + f.duration * t, width: width)
                        if x + reach > bagLeft && x - reach < bagRight { return (t, x) }
                    }
                    return nil
                }

                var spot = settle(near: falls, side: nil)
                var bounce = entry(restY: screen - (spot.bottom + rise))
                if let hit = bounce {
                    let left = settle(near: bagLeft - 1 - half, side: .left)
                    let right = settle(near: bagRight + 1 + half, side: .right)
                    // The nearer side, unless it is already piled well above
                    // the other.
                    let (near, far) = hit.x > width / 2 ? (right, left) : (left, right)
                    spot = near.bottom <= far.bottom + tall * 0.5 ? near : far
                    bounce = entry(restY: screen - (spot.bottom + rise)) ?? hit
                }

                // Its top is a low hump: full height in the middle, falling
                // away towards the tips.
                for c in column(spot.centre - half)...column(spot.centre + half) {
                    let dx = (Double(c) * step - spot.centre) / half
                    pile[c] = max(pile[c], spot.bottom + tall * (1 - 0.6 * dx * dx))
                }
                return Rest(slip: spot.centre - falls, height: spot.bottom + rise, bounce: bounce)
            }
        }
    }

    /// Long enough for the slowest, latest leaf to land and, on the 30th,
    /// for the bag to overflow. After that the timeline pauses and the pile
    /// stays as it lies.
    private static let total = 3.5 + 8.5 + Bag.overflowTime + Bag.sprayTime + 2

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let rests = Faller.rests(fallers, width: width, height: height)
            TimelineView(.animation(paused: finished || still)) { context in
                let elapsed = context.date.timeIntervalSince(start)
                // Fallers are in landing order, so those down so far are a prefix.
                let landed = still ? fallers.count : fallers.prefix { elapsed >= $0.lands }.count
                // On the 30th, once the last one is in, the bag overflows.
                let overflow: Double = {
                    guard fallers.count >= Bag.capacity, landed == fallers.count,
                          let last = fallers.last else { return 0 }
                    return still ? 1 : min((elapsed - last.lands) / Bag.overflowTime, 1)
                }()
                ZStack(alignment: .topLeading) {
                    // Behind the leaves: none comes to rest behind it, so it
                    // hides nothing, and one bouncing off shows in front.
                    bag(landed: landed, overflow: overflow)
                        .position(x: width / 2,
                                  y: height - Bag.bottom - Bag.height / 2)
                    ForEach(still ? 0..<0 : fallers.indices, id: \.self) { index in
                        let f = fallers[index]
                        // Clamped at 1: once landed, a leaf stops where it is.
                        let t = min((elapsed - f.delay) / f.duration, 1)
                        if t > 0 {
                            let rest = rests[index]
                            let restY = height - rest.height
                            let falling = -f.size + (restY + f.size) * t
                            let place: CGPoint = {
                                if let hit = rest.bounce, t > hit.t {
                                    // Off the bag: a hop up and sideways, then
                                    // down to where it rests.
                                    let s = (t - hit.t) / (1 - hit.t)
                                    let restX = f.left(at: f.lands, width: width) + rest.slip
                                    let across = 1 - pow(1 - s, 3)
                                    return CGPoint(x: hit.x + (restX - hit.x) * across,
                                                   y: falling - (30 + f.size * 0.3) * 4 * s * (1 - s))
                                }
                                // The slip happens over the last tenth of the fall.
                                let slip = rest.slip * min(max((t - 0.9) / 0.1, 0), 1)
                                return CGPoint(x: f.left(at: f.delay + f.duration * t, width: width) + slip,
                                               y: falling)
                            }()
                            piece(f)
                                .frame(width: f.size, height: f.size)
                                .rotationEffect(.degrees(f.tilt + f.spin * t))
                                .position(place)
                        }
                    }
                    // On the 30th, once the heap is up, the bag keeps
                    // overflowing: leaves and rabbits thrown out of its
                    // mouth to either side, for `Bag.sprayTime` seconds.
                    if overflow > 0, !still, let last = fallers.last {
                        let since = elapsed - last.lands - Bag.overflowTime * 0.5
                        let mouth = CGPoint(x: width / 2, y: height - Bag.bottom - Bag.height * 0.96)
                        ForEach(spray.indices, id: \.self) { i in
                            let s = spray[i]
                            let t = since - s.start
                            let y = mouth.y - s.rise * t + Spray.gravity / 2 * t * t
                            if t > 0, y < height + s.piece.size {
                                piece(s.piece)
                                    .frame(width: s.piece.size, height: s.piece.size)
                                    .rotationEffect(.degrees(s.spinRate * t))
                                    .position(x: mouth.x + s.across + s.speed * t, y: y)
                            }
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
            fallers = Faller.make(count: NovemberLeaves.fallerCount(onDay: day),
                                  ballot: ballot, thanksgiving: thanksgiving,
                                  blackFriday: blackFriday)
            if fallers.count >= Bag.capacity { spray = Spray.make() }
        }
        .task {
            try? await Task.sleep(for: .seconds(Self.total))
            finished = true
        }
    }

    // MARK: Leaf bag

    /// A brown paper lawn bag standing open in front of the middle of the
    /// hedge, its top folded over into a crumpled cuff and its
    /// sides creased. As each faller lands it fills a little from the
    /// bottom — full on the 30th, to just below the cuff — and the number
    /// printed on it counts up. Rabbits count too, so it ends on the date.
    private enum Bag {
        static let width: CGFloat = 60
        static let height: CGFloat = 134
        static let bottom: CGFloat = 26
        /// How high the fill reaches on the 30th, as a fraction of the
        /// frame from the top: a little below the cuff's crumpled edge, so
        /// some bare paper shows under its shadow.
        static let fullLine: CGFloat = 0.30
        /// One per November day.
        static let capacity = 30
        /// Seconds the overflow takes on the 30th.
        static let overflowTime = 1.4
        /// Seconds the full bag goes on throwing leaves out, on the 30th.
        static let sprayTime = 5.0

        /// A leaf in the overflow: where it ends up, as fractions of the
        /// bag's frame (above the top is negative), with its size in points,
        /// its turn, its shape and its colour.
        struct Spill {
            let x, y, size, turn: Double
            let kind: LeafKind
            let color: Int
        }

        /// The heap that rises out of the bag's mouth on the 30th, behind the
        /// cuff.
        static let heap: [Spill] = [
            Spill(x: 0.12, y: 0.07, size: 16, turn: -100, kind: .elm, color: 2),
            Spill(x: 0.20, y: 0.04, size: 18, turn: -50, kind: .maple, color: 0),
            Spill(x: 0.85, y: 0.05, size: 16, turn: 100, kind: .maple, color: 3),
            Spill(x: 0.38, y: -0.01, size: 20, turn: 20, kind: .oak, color: 1),
            Spill(x: 0.55, y: 0.03, size: 18, turn: -15, kind: .birch, color: 2),
            Spill(x: 0.72, y: 0.00, size: 19, turn: 55, kind: .elm, color: 3),
            Spill(x: 0.30, y: -0.06, size: 17, turn: 80, kind: .birch, color: 1),
            Spill(x: 0.66, y: -0.05, size: 17, turn: 10, kind: .oak, color: 0),
            Spill(x: 0.50, y: -0.08, size: 19, turn: -70, kind: .maple, color: 2),
        ]

        /// Leaves that tip over the rim once the heap is up: two caught on
        /// the cuff's corners, two slid partway down the sides.
        static let overspill: [Spill] = [
            Spill(x: -0.04, y: 0.16, size: 18, turn: -125, kind: .oak, color: 2),
            Spill(x: 1.03, y: 0.14, size: 18, turn: 130, kind: .maple, color: 0),
            Spill(x: 0.00, y: 0.36, size: 16, turn: -150, kind: .elm, color: 1),
            Spill(x: 1.00, y: 0.40, size: 16, turn: 160, kind: .birch, color: 3),
        ]

        /// The front panel below the cuff, as fractions of the bag's frame,
        /// clockwise from the top left. Its top is hidden under the cuff;
        /// its sides waver a little.
        static let front: [CGPoint] = [
            (0.03, 0.12), (0.97, 0.12),
            (0.97, 0.17), (0.98, 0.25), (0.95, 0.31), (0.97, 0.38), (0.96, 0.46),
            (0.98, 0.53), (0.95, 0.60), (0.97, 0.68), (0.96, 0.77), (0.98, 0.85),
            (0.96, 0.93), (0.97, 1.00),
            (0.03, 1.00),
            (0.04, 0.92), (0.02, 0.84), (0.05, 0.76), (0.03, 0.69), (0.04, 0.61),
            (0.02, 0.53), (0.05, 0.45), (0.03, 0.37), (0.04, 0.30), (0.02, 0.23),
            (0.03, 0.16),
        ].map { CGPoint(x: $0.0, y: $0.1) }

        /// The inside of the back wall, showing above the cuff's fold.
        static let back: [CGPoint] = [
            (0.06, 0.09), (0.10, 0.03), (0.22, 0.02), (0.35, 0.035), (0.50, 0.02),
            (0.65, 0.035), (0.78, 0.02), (0.90, 0.03), (0.94, 0.09),
        ].map { CGPoint(x: $0.0, y: $0.1) }

        /// The top turned down over the outside: a soft, slightly wavy fold
        /// along the top, a crumpled edge hanging below, a touch wider than
        /// the bag.
        static let cuff: [CGPoint] = [
            (0.00, 0.08), (0.12, 0.065), (0.25, 0.075), (0.38, 0.06), (0.50, 0.07),
            (0.62, 0.06), (0.75, 0.075), (0.88, 0.065), (1.00, 0.08),
            (0.99, 0.20), (0.93, 0.23), (0.88, 0.20), (0.82, 0.24), (0.76, 0.21),
            (0.70, 0.22), (0.64, 0.19), (0.58, 0.23), (0.52, 0.21), (0.46, 0.24),
            (0.40, 0.20), (0.34, 0.22), (0.28, 0.19), (0.22, 0.23), (0.16, 0.21),
            (0.10, 0.24), (0.05, 0.21), (0.01, 0.20),
        ].map { CGPoint(x: $0.0, y: $0.1) }

        /// Wrinkles in the cuff, where the fold bunches up.
        static let cuffCreases: [(CGPoint, CGPoint)] = [
            ((0.18, 0.08), (0.16, 0.19)), ((0.44, 0.08), (0.47, 0.20)),
            ((0.69, 0.08), (0.66, 0.18)), ((0.86, 0.08), (0.88, 0.17)),
        ].map { (CGPoint(x: $0.0.0, y: $0.0.1), CGPoint(x: $0.1.0, y: $0.1.1)) }

        /// Folds and wrinkles in the paper, as pairs of end points: the two
        /// gusset folds running the full height, then short creases.
        static let creases: [(CGPoint, CGPoint)] = [
            ((0.30, 0.12), (0.27, 1.00)), ((0.71, 0.11), (0.74, 1.00)),
            ((0.10, 0.30), (0.22, 0.36)), ((0.80, 0.26), (0.92, 0.31)),
            ((0.42, 0.20), (0.50, 0.27)), ((0.08, 0.80), (0.20, 0.76)),
            ((0.78, 0.84), (0.90, 0.80)), ((0.36, 0.88), (0.52, 0.92)),
            ((0.55, 0.40), (0.64, 0.36)),
        ].map { (CGPoint(x: $0.0.0, y: $0.0.1), CGPoint(x: $0.1.0, y: $0.1.1)) }
    }

    /// `overflow` runs from 0 to 1 as the bag overflows on the 30th: the
    /// heap rises out of its mouth over the first part, then leaves tip
    /// over the rim.
    private func bag(landed: Int, overflow: Double) -> some View {
        let dark = colorScheme == .dark
        let rising = min(overflow / 0.6, 1)
        let tipping = min(max((overflow - 0.4) / 0.6, 0), 1)
        func leaf(_ spill: Bag.Spill) -> some View {
            LeafPathShape(spill.kind.outline)
                .fill(AutumnColor.leaf(spill.color, dark: dark))
                .overlay(LeafPathShape(spill.kind.veins)
                    .stroke(Color.black.opacity(0.28), lineWidth: 0.5))
                .frame(width: spill.size, height: spill.size)
                .rotationEffect(.degrees(spill.turn))
        }
        let paper = Color(hex: dark ? 0x86643F : 0xCFA66F)
        let shade = Color(hex: dark ? 0x6A4D30 : 0xA98050)
        let inside = Color(hex: dark ? 0x553C25 : 0x93693F)
        let ink = Color(hex: dark ? 0x2E1E10 : 0x4A3220)
        let fill = Color(hex: dark ? 0xD9573A : 0xC0602A).opacity(dark ? 0.35 : 0.4)
        let level = min(Double(landed) / Double(Bag.capacity), 1) * (1 - Bag.fullLine)
        return ZStack {
            BagOutline(points: Bag.back).fill(inside)
            // The heap, rising from inside; the front and cuff hide its
            // lower part.
            if overflow > 0 {
                ForEach(Bag.heap.indices, id: \.self) { i in
                    let spill = Bag.heap[i]
                    leaf(spill)
                        .position(x: spill.x * Bag.width,
                                  y: spill.y * Bag.height + (1 - rising) * 26)
                }
            }
            BagOutline(points: Bag.front)
                // Shaded towards the sides, so it reads as round.
                .fill(LinearGradient(stops: [.init(color: shade, location: 0),
                                             .init(color: paper, location: 0.35),
                                             .init(color: paper, location: 0.6),
                                             .init(color: shade, location: 1)],
                                     startPoint: .leading, endPoint: .trailing))
            // The fill, rising from the bottom as fallers land.
            fill
                .frame(height: Bag.height * level)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .clipShape(BagOutline(points: Bag.front))
            BagCreases(creases: Bag.creases)
                .stroke(.black.opacity(0.22), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .clipShape(BagOutline(points: Bag.front))
            BagOutline(points: Bag.front)
                .stroke(shade, style: StrokeStyle(lineWidth: 1, lineJoin: .round))
            Text("\(landed)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ink.opacity(0.85))
                .contentTransition(.numericText(value: Double(landed)))
                .offset(y: Bag.height * 0.1)
            // The cuff, with a little shadow cast on the bag beneath it.
            BagOutline(points: Bag.cuff)
                .fill(LinearGradient(stops: [.init(color: shade, location: 0),
                                             .init(color: paper, location: 0.3),
                                             .init(color: paper, location: 0.65),
                                             .init(color: shade, location: 1)],
                                     startPoint: .leading, endPoint: .trailing))
                .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1.5)
            BagCreases(creases: Bag.cuffCreases)
                .stroke(.black.opacity(0.2), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
            BagOutline(points: Bag.cuff)
                .stroke(shade, style: StrokeStyle(lineWidth: 1, lineJoin: .round))
            // Over the rim: each starts at the mouth and slides out to
            // where it ends up, turning as it goes.
            if tipping > 0 {
                ForEach(Bag.overspill.indices, id: \.self) { i in
                    let spill = Bag.overspill[i]
                    let eased = 1 - pow(1 - tipping, 2)
                    let fromX = spill.x < 0.5 ? 0.25 : 0.75
                    leaf(spill)
                        .rotationEffect(.degrees(-spill.turn * (1 - eased) * 0.5))
                        .position(x: (fromX + (spill.x - fromX) * eased) * Bag.width,
                                  y: (0.02 + (spill.y - 0.02) * eased) * Bag.height)
                        .opacity(min(tipping * 3, 1))
                }
            }
        }
        .frame(width: Bag.width, height: Bag.height)
        .animation(.snappy, value: landed)
        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }

    /// A closed outline through points given as fractions of the frame.
    private struct BagOutline: Shape {
        let points: [CGPoint]

        func path(in rect: CGRect) -> Path {
            Path { path in
                path.addLines(points.map {
                    CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
                })
                path.closeSubpath()
            }
        }
    }

    private struct BagCreases: Shape {
        let creases: [(CGPoint, CGPoint)]

        func path(in rect: CGRect) -> Path {
            func p(_ point: CGPoint) -> CGPoint {
                CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
            }
            return Path { path in
                for (a, b) in creases {
                    path.move(to: p(a))
                    path.addLine(to: p(b))
                }
            }
        }
    }

    /// One faller, drawn to fill its frame.
    @ViewBuilder
    private func piece(_ f: Faller) -> some View {
        let dark = colorScheme == .dark
        let color = AutumnColor.leaf(f.colorIndex, dark: dark)
        if f.rabbit {
            switch f.standIn {
            case .turkey:
                Turkey(filled: f.filled, color: color)
            case .hare:
                Image(systemName: f.filled ? "hare.fill" : "hare")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color)
            case .shippingBox:
                ShippingBox(filled: f.filled, color: color)
            }
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

// MARK: - Stand-ins

/// What every fifth faller is drawn as: a rabbit most days, a turkey on
/// Thanksgiving, a shipping box on Black Friday.
fileprivate enum StandIn {
    case hare, turkey, shippingBox
}

/// A cardboard box seen from the front, with a smile across it in the
/// manner of a certain online shop's — centred, ending in an arrowhead on
/// the right. Outline or filled, like the hare; on the filled one the lid
/// seam, tape and smile are cut out. Drawn in a 100 × 100 box.
private struct ShippingBox: View {
    let filled: Bool
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let style = StrokeStyle(lineWidth: width * 0.05, lineCap: .round, lineJoin: .round)
            if filled {
                ZStack {
                    BoxShape().fill(color)
                    BoxMarks().stroke(style: style).blendMode(.destinationOut)
                }
                .compositingGroup()
            } else {
                ZStack {
                    BoxShape().stroke(color, style: style)
                    BoxMarks().stroke(color, style: style)
                }
            }
        }
    }
}

private struct BoxShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.18,
                                 width: rect.width * 0.84, height: rect.height * 0.64),
             cornerRadius: rect.width * 0.04)
    }
}

/// The lid seam, the tape down the middle of the lid, and the smile.
private struct BoxMarks: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var path = Path()
        path.move(to: p(0.08, 0.31)); path.addLine(to: p(0.92, 0.31))
        path.move(to: p(0.44, 0.18)); path.addLine(to: p(0.44, 0.31))
        path.move(to: p(0.56, 0.18)); path.addLine(to: p(0.56, 0.31))
        // The smile is symmetric about the middle; the arrowhead sits on
        // its right-hand end.
        path.move(to: p(0.28, 0.52))
        path.addQuadCurve(to: p(0.72, 0.52), control: p(0.50, 0.74))
        path.move(to: p(0.63, 0.50))
        path.addLine(to: p(0.73, 0.51))
        path.addLine(to: p(0.70, 0.61))
        return path
    }
}

// MARK: - Turkey

/// Thanksgiving's stand-in for the rabbits, since SF Symbols has no turkey:
/// a side-on turkey in one colour, made to sit beside `hare` and
/// `hare.fill` — an outline version and a filled one. Drawn in a 100 × 100
/// box, facing right, tail fanned up behind.
private struct Turkey: View {
    let filled: Bool
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let line = geometry.size.width * 0.055
            let style = StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round)
            if filled {
                // Solid, with the wing, feather divisions and eye cut out.
                ZStack {
                    TurkeyOutline().fill(color)
                    TurkeyDetail().stroke(style: style).blendMode(.destinationOut)
                    TurkeyEye().fill().blendMode(.destinationOut)
                }
                .compositingGroup()
            } else {
                ZStack {
                    TurkeyOutline().stroke(color, style: style)
                    TurkeyDetail().stroke(color, style: style)
                    TurkeyEye().fill(color)
                }
            }
        }
    }
}

/// Scales a path drawn in the 100 × 100 box into `rect`.
private func fitted(_ path: Path, in rect: CGRect) -> Path {
    path.applying(CGAffineTransform(translationX: rect.minX, y: rect.minY)
        .scaledBy(x: rect.width / 100, y: rect.height / 100))
}

private enum TurkeyGeometry {
    /// The fan's hub, hidden inside the body.
    static let hub = CGPoint(x: 40, y: 51)

    static func around(_ degrees: Double, _ radius: Double) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: hub.x + radius * cos(a), y: hub.y - radius * sin(a))
    }

    /// The valleys between the seven tail feathers, from low at the back
    /// round over the top to just behind the neck.
    static let valleys: [Double] = (0...7).map { 215 - Double($0) * 180 / 7 }

    /// The whole silhouette as one shape, so the outline version traces
    /// only its edge. Built once.
    static let outline: Path = {
        var fan = Path()
        fan.move(to: hub)
        fan.addLine(to: around(valleys[0], 30))
        for k in 0..<7 {
            let mid = (valleys[k] + valleys[k + 1]) / 2
            fan.addQuadCurve(to: around(valleys[k + 1], 30), control: around(mid, 44))
        }
        fan.closeSubpath()

        let body = Path(ellipseIn: CGRect(x: 34, y: 41, width: 46, height: 32))
        var neck = Path()
        neck.move(to: CGPoint(x: 66, y: 47))
        neck.addLine(to: CGPoint(x: 74, y: 22))
        neck.addLine(to: CGPoint(x: 84, y: 22))
        neck.addLine(to: CGPoint(x: 79, y: 51))
        neck.closeSubpath()
        let head = Path(ellipseIn: CGRect(x: 73, y: 13, width: 14, height: 14))
        var beak = Path()
        beak.move(to: CGPoint(x: 85, y: 17))
        beak.addLine(to: CGPoint(x: 94, y: 21))
        beak.addLine(to: CGPoint(x: 85, y: 24))
        beak.closeSubpath()
        let wattle = Path(ellipseIn: CGRect(x: 82, y: 22, width: 6, height: 13))
        var legs = Path()
        legs.addRoundedRect(in: CGRect(x: 51, y: 70, width: 4, height: 18), cornerSize: CGSize(width: 2, height: 2))
        legs.addRoundedRect(in: CGRect(x: 61, y: 70, width: 4, height: 18), cornerSize: CGSize(width: 2, height: 2))
        legs.addRoundedRect(in: CGRect(x: 46, y: 85, width: 11, height: 3.5), cornerSize: CGSize(width: 1.75, height: 1.75))
        legs.addRoundedRect(in: CGRect(x: 59, y: 85, width: 11, height: 3.5), cornerSize: CGSize(width: 1.75, height: 1.75))

        return [body, neck, head, beak, wattle, legs].reduce(fan) { $0.union($1) }
    }()

    /// The wing on the body and the lines between tail feathers.
    static let detail: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 46, y: 52))
        path.addQuadCurve(to: CGPoint(x: 71, y: 55), control: CGPoint(x: 58, y: 70))
        for k in 1..<7 {
            path.move(to: around(valleys[k], 19))
            path.addLine(to: around(valleys[k], 29))
        }
        return path
    }()

    static let eye = Path(ellipseIn: CGRect(x: 78.5, y: 16.5, width: 3.5, height: 3.5))
}

private struct TurkeyOutline: Shape {
    func path(in rect: CGRect) -> Path { fitted(TurkeyGeometry.outline, in: rect) }
}

private struct TurkeyDetail: Shape {
    func path(in rect: CGRect) -> Path { fitted(TurkeyGeometry.detail, in: rect) }
}

private struct TurkeyEye: Shape {
    func path(in rect: CGRect) -> Path { fitted(TurkeyGeometry.eye, in: rect) }
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

#Preview("Thanksgiving") {
    FallingLeaves(day: 26, thanksgiving: true, start: Date())
        .background {
            Color.furlingNovemberBackground
            NovemberHedge()
        }
}

#Preview("Black Friday") {
    FallingLeaves(day: 27, blackFriday: true, start: Date())
        .background {
            Color.furlingNovemberBackground
            NovemberHedge()
        }
}
