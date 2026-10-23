import AppKit
import Carbon.HIToolbox
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let store = ColorStore.shared
    private var hotKey: HotKey?
    private var sampler: NSColorSampler?
    private var chevronWidth: CGFloat = 0
    private var popoverClosedAt = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = makeStatusImage()
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Pipka — click to pick, arrow for formats"
        }

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(store: store, onPick: { [weak self] in self?.pick() })
        )

        // ⌃⌥⌘C — pick from anywhere
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(controlKey | optionKey | cmdKey)) { [weak self] in
            self?.pick()
        }
    }

    /// Eyedropper + small chevron drawn as one template image.
    private func makeStatusImage() -> NSImage? {
        guard
            let drop = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: "Pipka")?
                .withSymbolConfiguration(.init(pointSize: 14, weight: .regular)),
            let chevron = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Formats")?
                .withSymbolConfiguration(.init(pointSize: 8, weight: .bold))
        else { return nil }

        let gap: CGFloat = 4
        let size = NSSize(width: drop.size.width + gap + chevron.size.width,
                          height: max(drop.size.height, chevron.size.height))
        chevronWidth = chevron.size.width + gap / 2 + 4
        let image = NSImage(size: size, flipped: false) { _ in
            drop.draw(in: NSRect(x: 0, y: (size.height - drop.size.height) / 2,
                                 width: drop.size.width, height: drop.size.height))
            chevron.draw(in: NSRect(x: drop.size.width + gap, y: (size.height - chevron.size.height) / 2,
                                    width: chevron.size.width, height: chevron.size.height))
            return true
        }
        image.isTemplate = true
        return image
    }

    // Eyedropper part picks, the chevron (or right click) opens the formats popover.
    @objc private func statusClicked() {
        guard let button = statusItem.button, let event = NSApp.currentEvent else { return }
        let x = button.convert(event.locationInWindow, from: nil).x
        let onChevron = x >= button.bounds.maxX - chevronWidth - 4
        if event.type == .rightMouseUp || onChevron {
            togglePopover()
        } else {
            pick()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        // The click that closed a transient popover arrives here too — don't reopen it.
        guard Date().timeIntervalSince(popoverClosedAt) > 0.25 else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        popoverClosedAt = Date()
    }

    func pick() {
        if popover.isShown { popover.performClose(nil) }
        guard sampler == nil else { return }
        let sampler = NSColorSampler()
        self.sampler = sampler
        sampler.show { [weak self] picked in
            DispatchQueue.main.async {
                guard let self else { return }
                self.sampler = nil
                guard let picked, let color = RGBColor(picked) else { return }
                self.store.color = color
                self.store.copy(color)
                Toast.shared.show(color: color, text: color.string(self.store.format))
            }
        }
    }
}
