// Renders Resources/AppIcon.icns: run `swift scripts/make-icon.swift` from the repo root.
import AppKit

func render(_ px: Int) -> Data {
    let s = CGFloat(px) / 1024
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: s, y: s)
    let rgb = CGColorSpace(name: CGColorSpace.sRGB)!
    func c(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: a)
    }

    // Background squircle (Apple icon grid: 824pt body inset 100pt)
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bg = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: c(0x000000, 0.35))
    ctx.addPath(bg); ctx.setFillColor(c(0x1B1B22)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(bg); ctx.clip()
    ctx.drawLinearGradient(CGGradient(colorsSpace: rgb, colors: [c(0x2C2B3A), c(0x15151B)] as CFArray, locations: [0, 1])!,
                           start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()

    // Droplet
    let cx: CGFloat = 512, cy: CGFloat = 430, r: CGFloat = 205
    let top = CGPoint(x: cx, y: 800)
    let drop = CGMutablePath()
    drop.move(to: top)
    drop.addCurve(to: CGPoint(x: cx + r, y: cy), control1: CGPoint(x: cx + 50, y: 700), control2: CGPoint(x: cx + r, y: 590))
    drop.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: 0, endAngle: .pi, clockwise: true)
    drop.addCurve(to: top, control1: CGPoint(x: cx - r, y: 590), control2: CGPoint(x: cx - 50, y: 700))
    drop.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: c(0x7C4DFF, 0.55))
    ctx.addPath(drop); ctx.setFillColor(c(0xFF4F8B)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(drop); ctx.clip()
    ctx.drawLinearGradient(
        CGGradient(colorsSpace: rgb, colors: [c(0xFF6A88), c(0xB84DFF), c(0x3D7BFF)] as CFArray, locations: [0, 0.55, 1])!,
        start: CGPoint(x: 330, y: 780), end: CGPoint(x: 700, y: 230), options: [])
    // Highlight
    ctx.setFillColor(c(0xFFFFFF, 0.38))
    ctx.fillEllipse(in: CGRect(x: cx - 125, y: cy + 20, width: 70, height: 110))
    ctx.restoreGState()

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! p.run(); p.waitUntilExit()
try! render(512).write(to: URL(fileURLWithPath: "Resources/icon.png"))
print("Resources/AppIcon.icns written")
