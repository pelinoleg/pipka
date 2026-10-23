import AppKit
import SwiftUI

enum ColorFormat: String, CaseIterable, Identifiable {
    case hex, rgb, rgba, hsl, oklch, oklab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hex: "HEX"
        case .rgb: "RGB"
        case .rgba: "RGBA"
        case .hsl: "HSL"
        case .oklch: "OKLCH"
        case .oklab: "OKLab"
        }
    }
}

struct RGBColor: Codable, Hashable {
    var r: Double
    var g: Double
    var b: Double

    init?(_ color: NSColor) {
        guard let c = color.usingColorSpace(.sRGB) else { return nil }
        r = min(max(Double(c.redComponent), 0), 1)
        g = min(max(Double(c.greenComponent), 0), 1)
        b = min(max(Double(c.blueComponent), 0), 1)
    }

    private var r255: Int { Int((r * 255).rounded()) }
    private var g255: Int { Int((g * 255).rounded()) }
    private var b255: Int { Int((b * 255).rounded()) }

    var hex: String { String(format: "#%02X%02X%02X", r255, g255, b255) }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b) }

    private static func linear(_ v: Double) -> Double {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    /// Readable text color on top of this color.
    var isLight: Bool { oklab.l > 0.7 }

    var hsl: (h: Int, s: Int, l: Int) {
        let maxV = max(r, g, b), minV = min(r, g, b)
        let l = (maxV + minV) / 2
        let d = maxV - minV
        guard d > 0 else { return (0, 0, Int((l * 100).rounded())) }
        let s = d / (1 - abs(2 * l - 1))
        var h: Double
        switch maxV {
        case r: h = ((g - b) / d).truncatingRemainder(dividingBy: 6)
        case g: h = (b - r) / d + 2
        default: h = (r - g) / d + 4
        }
        h *= 60
        if h < 0 { h += 360 }
        return (Int(h.rounded()) % 360, Int((s * 100).rounded()), Int((l * 100).rounded()))
    }

    /// https://bottosson.github.io/posts/oklab/
    var oklab: (l: Double, a: Double, b: Double) {
        let lr = Self.linear(r), lg = Self.linear(g), lb = Self.linear(b)
        let l = cbrt(0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb)
        let m = cbrt(0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb)
        let s = cbrt(0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb)
        return (
            0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }

    func string(_ format: ColorFormat) -> String {
        switch format {
        case .hex:
            return hex
        case .rgb:
            return "rgb(\(r255), \(g255), \(b255))"
        case .rgba:
            return "rgba(\(r255), \(g255), \(b255), 1)"
        case .hsl:
            let v = hsl
            return "hsl(\(v.h), \(v.s)%, \(v.l)%)"
        case .oklab:
            let v = oklab
            return String(format: "oklab(%.1f%% %.3f %.3f)", v.l * 100, Self.clean(v.a), Self.clean(v.b))
        case .oklch:
            let v = oklab
            let c = sqrt(v.a * v.a + v.b * v.b)
            var h = c < 0.0005 ? 0 : atan2(v.b, v.a) * 180 / .pi
            if h < 0 { h += 360 }
            return String(format: "oklch(%.1f%% %.3f %.1f)", v.l * 100, Self.clean(c), h)
        }
    }

    /// Avoids "-0.000" for greys.
    private static func clean(_ v: Double) -> Double { abs(v) < 0.0005 ? 0 : v }
}

final class ColorStore: ObservableObject {
    static let shared = ColorStore()

    @Published var color: RGBColor? { didSet { save() } }
    @Published var format: ColorFormat { didSet { save() } }

    private let defaults = UserDefaults.standard

    private init() {
        if let data = defaults.data(forKey: "color") {
            color = try? JSONDecoder().decode(RGBColor.self, from: data)
        }
        format = ColorFormat(rawValue: defaults.string(forKey: "format") ?? "") ?? .hex
    }

    func copy(_ color: RGBColor, as format: ColorFormat? = nil) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(color.string(format ?? self.format), forType: .string)
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(color), forKey: "color")
        defaults.set(format.rawValue, forKey: "format")
    }
}
