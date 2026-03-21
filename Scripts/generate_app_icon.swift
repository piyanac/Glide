import AppKit
import Foundation

let fileManager = FileManager.default
let arguments = CommandLine.arguments

guard arguments.count >= 2 else {
    fputs("Usage: swift generate_app_icon.swift <output-directory>\n", stderr)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct IconSpec {
    let filename: String
    let size: CGFloat
}

let specs: [IconSpec] = [
    .init(filename: "icon_16x16.png", size: 16),
    .init(filename: "icon_16x16@2x.png", size: 32),
    .init(filename: "icon_32x32.png", size: 32),
    .init(filename: "icon_32x32@2x.png", size: 64),
    .init(filename: "icon_128x128.png", size: 128),
    .init(filename: "icon_128x128@2x.png", size: 256),
    .init(filename: "icon_256x256.png", size: 256),
    .init(filename: "icon_256x256@2x.png", size: 512),
    .init(filename: "icon_512x512.png", size: 512),
    .init(filename: "icon_512x512@2x.png", size: 1024),
]

func makeColor(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func makeBitmap(size: CGFloat) -> NSBitmapImageRep {
    let pixelsWide = Int(size.rounded())
    let pixelsHigh = Int(size.rounded())
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelsWide,
        pixelsHigh: pixelsHigh,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap")
    }

    bitmap.size = NSSize(width: size, height: size)
    return bitmap
}

func arcPath(size: CGFloat, lineWidth: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = lineWidth

    let y = size * 0.52
    path.move(to: NSPoint(x: size * -0.02, y: y - size * 0.015))
    path.curve(
        to: NSPoint(x: size * 0.44, y: size * 0.50),
        controlPoint1: NSPoint(x: size * 0.12, y: y + size * 0.05),
        controlPoint2: NSPoint(x: size * 0.32, y: y + size * 0.02)
    )
    path.curve(
        to: NSPoint(x: size * 0.50, y: size * 0.535),
        controlPoint1: NSPoint(x: size * 0.47, y: size * 0.50),
        controlPoint2: NSPoint(x: size * 0.49, y: size * 0.52)
    )
    path.curve(
        to: NSPoint(x: size * 0.56, y: size * 0.50),
        controlPoint1: NSPoint(x: size * 0.51, y: size * 0.52),
        controlPoint2: NSPoint(x: size * 0.53, y: size * 0.50)
    )
    path.curve(
        to: NSPoint(x: size * 1.02, y: y - size * 0.015),
        controlPoint1: NSPoint(x: size * 0.68, y: y + size * 0.02),
        controlPoint2: NSPoint(x: size * 0.88, y: y + size * 0.05)
    )
    return path
}

func centerMarkPath(size: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: size * 0.46, y: size * 0.56))
    path.line(to: NSPoint(x: size * 0.50, y: size * 0.49))
    path.line(to: NSPoint(x: size * 0.54, y: size * 0.56))
    path.line(to: NSPoint(x: size * 0.50, y: size * 0.62))
    path.close()
    return path
}

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let bitmap = makeBitmap(size: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    makeColor(11, 17, 24).setFill()
    rect.fill()

    let centerGlow = NSGradient(colors: [
        makeColor(255, 152, 48, 0.55),
        makeColor(255, 152, 48, 0.10),
        makeColor(11, 17, 24, 0.0),
    ])!
    centerGlow.draw(
        in: NSBezierPath(ovalIn: NSRect(x: size * 0.17, y: size * 0.16, width: size * 0.66, height: size * 0.66)),
        relativeCenterPosition: .zero
    )

    let lowerGlow = NSGradient(colors: [
        makeColor(255, 140, 38, 0.30),
        makeColor(255, 140, 38, 0.0),
    ])!
    lowerGlow.draw(
        in: NSBezierPath(ovalIn: NSRect(x: size * 0.10, y: size * 0.01, width: size * 0.80, height: size * 0.48)),
        relativeCenterPosition: .zero
    )

    let glowPath = arcPath(size: size, lineWidth: max(6, size * 0.055))
    NSGraphicsContext.current?.imageInterpolation = .high
    makeColor(255, 174, 80, 0.18).setStroke()
    glowPath.stroke()

    let mainPath = arcPath(size: size, lineWidth: max(2, size * 0.022))
    makeColor(255, 194, 108, 0.95).setStroke()
    mainPath.stroke()

    let highlightPath = arcPath(size: size, lineWidth: max(1.2, size * 0.009))
    makeColor(255, 247, 208, 0.65).setStroke()
    highlightPath.stroke()

    let centerPath = centerMarkPath(size: size)
    let centerGradient = NSGradient(colors: [
        makeColor(255, 252, 235, 1),
        makeColor(255, 211, 123, 1),
        makeColor(255, 154, 56, 1),
    ])!
    centerGradient.draw(in: centerPath, angle: -90)

    let flarePath = NSBezierPath(ovalIn: NSRect(x: size * 0.43, y: size * 0.44, width: size * 0.14, height: size * 0.14))
    let flareGradient = NSGradient(colors: [
        makeColor(255, 220, 138, 0.65),
        makeColor(255, 170, 70, 0.0),
    ])!
    flareGradient.draw(in: flarePath, relativeCenterPosition: .zero)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

for spec in specs {
    let bitmap = drawIcon(size: spec.size)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode \(spec.filename)")
    }
    try data.write(to: outputDirectory.appendingPathComponent(spec.filename))
}
