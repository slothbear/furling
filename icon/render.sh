#!/bin/sh
# Renders furling.svg to the 1024 app icon PNG, flattened to RGB with no
# alpha channel — upload validation rejects an icon that has one.
#
# The hare is the system `hare.fill` symbol, the same creature the widget
# shows. It is rendered from the installed SF Symbols set at run time into a
# scratch directory rather than kept in the repo, so this checkout carries no
# copy of Apple's artwork.
#
# Everything here ships with macOS and Xcode. Nothing to install.
set -e
cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ASSETS="../Furling/Assets.xcassets/AppIcon.appiconset"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

[ -x "$CHROME" ] || { echo "Chrome not found at $CHROME" >&2; exit 1; }

cat > "$WORK/symbol.swift" <<'SWIFT'
import AppKit

let args = CommandLine.arguments
let name = args[1], hex = args[2], out = args[3]

func color(_ hex: String) -> NSColor {
    var v: UInt64 = 0
    Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
                   green: CGFloat((v >> 8) & 0xff) / 255,
                   blue: CGFloat(v & 0xff) / 255, alpha: 1)
}

guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil),
      let sized = symbol.withSymbolConfiguration(
          NSImage.SymbolConfiguration(pointSize: 1400, weight: .regular)) else {
    FileHandle.standardError.write("symbol \(name) unavailable\n".data(using: .utf8)!)
    exit(1)
}

let size = sized.size
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                 pixelsWide: Int(size.width.rounded()),
                                 pixelsHigh: Int(size.height.rounded()),
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0) else { exit(1) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let rect = NSRect(origin: .zero, size: size)
sized.draw(in: rect)
color(hex).set()
rect.fill(using: .sourceAtop)
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("hare \(Int(size.width))x\(Int(size.height))")
SWIFT

cat > "$WORK/flatten.swift" <<'SWIFT'
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(1) }

let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
guard let context = CGContext(data: nil, width: image.width, height: image.height,
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(1) }
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fill(rect)
context.draw(image, in: rect)

guard let flattened = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL,
                                                        UTType.png.identifier as CFString, 1, nil)
else { exit(1) }
CGImageDestinationAddImage(destination, flattened, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
SWIFT

# Each variant is one SVG plus the colour its hare is tinted. The SVG is
# inlined rather than loaded through an <img> tag: an SVG embedded as an image
# runs in secure static mode, where its reference to hare.png is silently
# dropped and the hare simply never appears.
render() {
  svg=$1 hare=$2 out=$3
  swift "$WORK/symbol.swift" hare.fill "$hare" "$WORK/hare.png" >/dev/null
  {
    printf '%s' '<!doctype html><meta charset="utf-8">'
    printf '%s' '<style>html,body{margin:0;padding:0;background:#fff}svg{display:block}</style>'
    cat "$svg"
  } > "$WORK/render.html"
  "$CHROME" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --window-size=1024,1024 \
    --screenshot="$WORK/rgba.png" "file://$WORK/render.html" >/dev/null 2>&1
  swift "$WORK/flatten.swift" "$WORK/rgba.png" "$ASSETS/$out"
  echo "wrote $out $(sips -g pixelWidth -g hasAlpha "$ASSETS/$out" | tr '\n' ' ')"
}

render furling.svg "#22371e" AppIcon-1024.png
render furling-dark.svg "#eef3f4" AppIcon-1024-dark.png
