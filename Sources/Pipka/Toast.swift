import AppKit
import SwiftUI

/// Small "copied" pill that pops up next to the cursor and fades away.
final class Toast {
    static let shared = Toast()

    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(color: RGBColor, text: String) {
        let content = NSHostingView(rootView: ToastView(color: color, text: text))
        let size = content.fittingSize

        let effect = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        effect.material = .hudWindow
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.appearance = NSAppearance(named: .vibrantDark)
        effect.maskImage = NSImage(size: size, flipped: false) { rect in
            NSBezierPath(roundedRect: rect, xRadius: size.height / 2, yRadius: size.height / 2).fill()
            return true
        }
        content.frame = effect.bounds
        effect.addSubview(content)

        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.contentView = effect
        panel.setFrame(frame(for: size), display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1
        }

        hideWork?.cancel()
        let work = DispatchWorkItem { [weak panel] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.35
                panel?.animator().alphaValue = 0
            }, completionHandler: { panel?.orderOut(nil) })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return panel
    }

    private func frame(for size: NSSize) -> NSRect {
        let mouse = NSEvent.mouseLocation
        var origin = NSPoint(x: mouse.x + 18, y: mouse.y - size.height - 18)
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            let v = screen.visibleFrame
            origin.x = min(max(origin.x, v.minX + 8), v.maxX - size.width - 8)
            origin.y = min(max(origin.y, v.minY + 8), v.maxY - size.height - 8)
        }
        return NSRect(origin: origin, size: size)
    }
}

private struct ToastView: View {
    let color: RGBColor
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Droplet()
                .fill(color.color)
                .overlay(Droplet().stroke(.white.opacity(0.4), lineWidth: 1))
                .frame(width: 14, height: 19.6)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 7)
        .fixedSize()
    }
}
