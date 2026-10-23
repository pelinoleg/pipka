import AppKit
import SwiftUI

/// The Pipka droplet, same proportions as the app icon (height = 1.4 × width).
struct Droplet: Shape {
    func path(in rect: CGRect) -> Path {
        Path(Droplet.cgPath(in: rect, flipped: true))
    }

    /// `flipped` = y grows downwards (SwiftUI); AppKit drawing uses y-up.
    static func cgPath(in rect: CGRect, flipped: Bool) -> CGPath {
        let r = min(rect.width / 2, rect.height / 2.8)
        let cx = rect.midX
        // Work in y-up coordinates from the bottom of the rect, then mirror if needed.
        let base = rect.midY - 1.4 * r
        func p(_ x: CGFloat, _ yUp: CGFloat) -> CGPoint {
            CGPoint(x: x, y: flipped ? rect.maxY - (yUp - rect.minY) : yUp)
        }
        let cy = base + r
        let top = cy + 1.8 * r

        let path = CGMutablePath()
        path.move(to: p(cx, top))
        path.addCurve(to: p(cx + r, cy), control1: p(cx + 0.24 * r, cy + 1.32 * r), control2: p(cx + r, cy + 0.78 * r))
        path.addArc(center: p(cx, cy), radius: r, startAngle: 0, endAngle: .pi, clockwise: !flipped)
        path.addCurve(to: p(cx, top), control1: p(cx - r, cy + 0.78 * r), control2: p(cx - 0.24 * r, cy + 1.32 * r))
        path.closeSubpath()
        return path
    }
}

extension RGBColor {
    var cgColor: CGColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1).cgColor }

    /// Mixes towards white (1) or black (0).
    func mixed(with v: Double, by t: Double) -> RGBColor {
        var c = self
        c.r += (v - r) * t; c.g += (v - g) * t; c.b += (v - b) * t
        return c
    }

    /// Lighter-to-darker gradient of the same color.
    var dropGradient: LinearGradient {
        LinearGradient(colors: [mixed(with: 1, by: 0.3).color, color, mixed(with: 0, by: 0.25).color],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum StatusIcon {
    static let gap: CGFloat = 4
    static let chevronSize = NSSize(width: 7, height: 4)

    /// Droplet filled with the last picked color + a chevron in the menu bar's text color.
    static func image(for color: RGBColor?) -> NSImage {
        let dropSize = NSSize(width: 12, height: 16.8)
        let size = NSSize(width: dropSize.width + gap + chevronSize.width + 1, height: 18)

        let image = NSImage(size: size, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let dropRect = CGRect(x: 0.5, y: (size.height - dropSize.height) / 2, width: dropSize.width, height: dropSize.height)
            let path = Droplet.cgPath(in: dropRect.insetBy(dx: 0.5, dy: 0.5), flipped: false)

            ctx.saveGState()
            ctx.addPath(path)
            ctx.clip()
            // Same color, a bit lighter at the top and darker at the bottom — gives the drop some volume.
            let colors: [CGColor] = color.map { [$0.mixed(with: 1, by: 0.3).cgColor, $0.cgColor, $0.mixed(with: 0, by: 0.25).cgColor] }
                ?? [NSColor(srgbRed: 1, green: 0.42, blue: 0.53, alpha: 1).cgColor,
                    NSColor(srgbRed: 0.72, green: 0.3, blue: 1, alpha: 1).cgColor,
                    NSColor(srgbRed: 0.24, green: 0.48, blue: 1, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                      colors: colors as CFArray, locations: [0, 0.5, 1])!
            ctx.drawLinearGradient(gradient, start: CGPoint(x: dropRect.minX, y: dropRect.maxY),
                                   end: CGPoint(x: dropRect.maxX, y: dropRect.minY), options: [])
            ctx.restoreGState()

            // Hairline border that contrasts with the fill, so the drop never melts into the menu bar.
            let light = color?.isLight ?? false
            ctx.addPath(path)
            ctx.setStrokeColor(light ? NSColor.black.withAlphaComponent(0.35).cgColor
                                     : NSColor.white.withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(1)
            ctx.strokePath()

            // Chevron — labelColor resolves against the menu bar's current appearance.
            let cx = dropRect.maxX + gap + chevronSize.width / 2
            let cy = size.height / 2 - 0.5
            let chevron = NSBezierPath()
            chevron.move(to: NSPoint(x: cx - chevronSize.width / 2, y: cy + chevronSize.height / 2))
            chevron.line(to: NSPoint(x: cx, y: cy - chevronSize.height / 2))
            chevron.line(to: NSPoint(x: cx + chevronSize.width / 2, y: cy + chevronSize.height / 2))
            chevron.lineWidth = 1.6
            chevron.lineCapStyle = .round
            chevron.lineJoinStyle = .round
            NSColor.labelColor.setStroke()
            chevron.stroke()
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = "Pipka"
        return image
    }

    /// Width of the clickable chevron zone at the right edge of the button.
    static var chevronZone: CGFloat { chevronSize.width + gap + 6 }
}
