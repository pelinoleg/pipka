import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let store = ColorStore.shared
    private var hotKey: HotKey?
    private var sampler: NSColorSampler?
    private var colorObserver: AnyCancellable?
    private var popoverClosedAt = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Pipka — click to pick, arrow for formats"
        }

        colorObserver = store.$color.sink { [weak self] color in
            self?.statusItem.button?.image = StatusIcon.image(for: color)
        }

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(store: store, onPick: { [weak self] in self?.pick() })
        )

        // ⇧⌘C — pick from anywhere
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(shiftKey | cmdKey)) { [weak self] in
            self?.pick()
        }
    }

    // Droplet part picks, the chevron (or right click) opens the formats popover.
    @objc private func statusClicked() {
        guard let button = statusItem.button, let event = NSApp.currentEvent else { return }
        let x = button.convert(event.locationInWindow, from: nil).x
        let onChevron = x >= button.bounds.maxX - StatusIcon.chevronZone
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
