#!/usr/bin/env swift
// Generate IBPractice app icon at 1024×1024.
//   swift generate_icon.swift <variant> <output.png>
// variant: light | dark | tinted

import AppKit
import CoreText
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: generate_icon.swift <light|dark|tinted> <output.png>\n", stderr)
    exit(1)
}

let variant = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

struct Palette {
    let canvas: NSColor
    let ink: NSColor
    let gold: NSColor
    let rule: NSColor
    let muted: NSColor
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red:   CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF)  / 255,
        blue:  CGFloat(hex & 0xFF)         / 255,
        alpha: alpha
    )
}

let palette: Palette = {
    switch variant {
    case "dark":
        return Palette(
            canvas: color(0x0A1426),
            ink:    color(0xECE6D2),
            gold:   color(0xD4AC4B),
            rule:   color(0xD4AC4B, 0.55),
            muted:  color(0x8DA0BF)
        )
    case "tinted":
        // iOS 18 tinted mode: monochrome silhouette on black, iOS recolors.
        return Palette(
            canvas: color(0x000000),
            ink:    color(0xFFFFFF),
            gold:   color(0xCCCCCC),
            rule:   color(0x888888),
            muted:  color(0x999999)
        )
    default:
        return Palette(
            canvas: color(0xEFECE5),
            ink:    color(0x161E2E),
            gold:   color(0x8E6B1F),
            rule:   color(0x8E6B1F, 0.85),
            muted:  color(0x5A5345)
        )
    }
}()

let size = NSSize(width: 1024, height: 1024)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
) else { fputs("could not allocate bitmap\n", stderr); exit(1) }

NSGraphicsContext.saveGraphicsState()
guard let ctx = NSGraphicsContext(bitmapImageRep: bitmap) else { exit(1) }
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

// 1. Canvas — full bleed (iOS applies the squircle mask).
palette.canvas.setFill()
cg.fill(CGRect(origin: .zero, size: size))

// 2. Subtle vignette / grain texture for the Ledger variant.
if variant == "light" {
    cg.saveGState()
    let stops: [CGFloat] = [0, 1]
    let colors = [
        color(0x000000, 0.0).cgColor,
        color(0x8E6B1F, 0.07).cgColor
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: colors, locations: stops) {
        cg.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: size.width/2, y: size.height/2),
            startRadius: 100,
            endCenter:   CGPoint(x: size.width/2, y: size.height/2),
            endRadius:   size.width * 0.75,
            options: []
        )
    }
    cg.restoreGState()
}

// 3. Top eyebrow: "IB · 400"
let monoFont = NSFont.monospacedSystemFont(ofSize: 56, weight: .semibold)
let eyebrow = "IB · 400"
let eyebrowAttrs: [NSAttributedString.Key: Any] = [
    .font: monoFont,
    .foregroundColor: palette.muted,
    .kern: 10
]
let eyebrowSize = (eyebrow as NSString).size(withAttributes: eyebrowAttrs)
(eyebrow as NSString).draw(
    at: CGPoint(x: (size.width - eyebrowSize.width) / 2, y: 820),
    withAttributes: eyebrowAttrs
)

// 4. Big serif IB monogram (centered, optical baseline).
let serifDescriptor: NSFontDescriptor = {
    let base = NSFont.systemFont(ofSize: 640, weight: .bold)
    if let d = base.fontDescriptor.withDesign(.serif) { return d }
    return base.fontDescriptor
}()
let serifFont = NSFont(descriptor: serifDescriptor, size: 640) ?? NSFont.boldSystemFont(ofSize: 640)
let monogram = "IB"
let monogramAttrs: [NSAttributedString.Key: Any] = [
    .font: serifFont,
    .foregroundColor: palette.ink,
    .kern: -30
]
let monogramSize = (monogram as NSString).size(withAttributes: monogramAttrs)
let monogramOrigin = CGPoint(
    x: (size.width - monogramSize.width) / 2,
    y: (size.height - monogramSize.height) / 2 - 20
)
(monogram as NSString).draw(at: monogramOrigin, withAttributes: monogramAttrs)

// 5. Gold rule under the monogram.
let ruleY: CGFloat = 240
let ruleW: CGFloat = 360
let ruleRect = CGRect(x: (size.width - ruleW) / 2, y: ruleY, width: ruleW, height: 6)
palette.rule.setFill()
cg.fill(ruleRect)

// 6. Bottom mono caption: "PRACTICE"
let captionFont = NSFont.monospacedSystemFont(ofSize: 64, weight: .semibold)
let caption = "PRACTICE"
let captionAttrs: [NSAttributedString.Key: Any] = [
    .font: captionFont,
    .foregroundColor: palette.gold,
    .kern: 14
]
let captionSize = (caption as NSString).size(withAttributes: captionAttrs)
(caption as NSString).draw(
    at: CGPoint(x: (size.width - captionSize.width) / 2, y: 140),
    withAttributes: captionAttrs
)

// 7. Tiny corner gold ticks — ledger-paper detail (skipped on tinted).
if variant != "tinted" {
    palette.rule.setFill()
    let inset: CGFloat = 60
    let tick: CGFloat = 36
    let thick: CGFloat = 4
    // top-left
    cg.fill(CGRect(x: inset, y: size.height - inset - thick, width: tick, height: thick))
    cg.fill(CGRect(x: inset, y: size.height - inset - tick, width: thick, height: tick))
    // top-right
    cg.fill(CGRect(x: size.width - inset - tick, y: size.height - inset - thick, width: tick, height: thick))
    cg.fill(CGRect(x: size.width - inset - thick, y: size.height - inset - tick, width: thick, height: tick))
    // bottom-left
    cg.fill(CGRect(x: inset, y: inset, width: tick, height: thick))
    cg.fill(CGRect(x: inset, y: inset, width: thick, height: tick))
    // bottom-right
    cg.fill(CGRect(x: size.width - inset - tick, y: inset, width: tick, height: thick))
    cg.fill(CGRect(x: size.width - inset - thick, y: inset, width: thick, height: tick))
}

NSGraphicsContext.restoreGraphicsState()

// Export PNG.
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("PNG encode failed\n", stderr); exit(1)
}
let url = URL(fileURLWithPath: outputPath)
do {
    try pngData.write(to: url)
    print("wrote \(outputPath) (\(pngData.count) bytes)")
} catch {
    fputs("write failed: \(error)\n", stderr); exit(1)
}
