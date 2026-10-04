import AppKit
import SwiftUI

final class MenuPanel: NSPanel {
    var onCancel: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onCancel?() }
}

// A panel opened from the menu bar is often not key yet; without this the first click only
// activates the window and never reaches the button.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var panel: MenuPanel?
    private var clickMonitor: Any?
    private var lastHide = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Sleep display")
        button.toolTip = "Sleep display"
        button.target = self
        button.action = #selector(togglePanel)
        #if DEBUG_OPEN
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.togglePanel() }
        #endif
    }

    @objc private func togglePanel() {
        if panel != nil {
            hidePanel()
        } else if Date().timeIntervalSince(lastHide) > 0.2 {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }

        let host = FirstMouseHostingView(rootView: SleepPanelView(
            onSleep: { [weak self] in self?.sleepDisplay() },
            onQuit: { NSApp.terminate(nil) }
        ).environment(\.controlActiveState, .key))
        let size = host.fittingSize

        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        background.material = .popover
        background.state = .active
        background.blendingMode = .behindWindow
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.layer?.cornerCurve = .continuous
        background.layer?.masksToBounds = true
        host.frame = background.bounds
        host.autoresizingMask = [.width, .height]
        background.addSubview(host)

        let panel = MenuPanel(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        panel.contentView = background
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.onCancel = { [weak self] in self?.hidePanel() }

        // Hang the panel off the icon's own bottom edge. If a menu bar manager has pushed the
        // icon off-screen, there is nothing to hang from, so use the top-right corner instead.
        let screen = buttonWindow.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let iconIsOnScreen = screen.frame.contains(NSPoint(x: buttonFrame.midX, y: buttonFrame.midY))
        let anchorX = iconIsOnScreen ? buttonFrame.midX - size.width / 2 : screen.frame.maxX - size.width - 10
        let barBottom = iconIsOnScreen ? buttonFrame.minY : screen.frame.maxY - NSStatusBar.system.thickness
        let x = min(max(anchorX, screen.frame.minX + 8), screen.frame.maxX - size.width - 8)
        panel.setFrameOrigin(NSPoint(x: x, y: barBottom - size.height - 4))

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.12
            panel.animator().alphaValue = 1
        }
        self.panel = panel
        button.highlight(true)

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePanel()
        }
    }

    private func hidePanel() {
        guard let panel else { return }
        lastHide = Date()
        statusItem.button?.highlight(false)
        panel.orderOut(nil)
        self.panel = nil
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        clickMonitor = nil
        NSApp.deactivate()
    }

    private func sleepDisplay() {
        sleepOnceInputIsIdle(giveUpAt: Date().addingTimeInterval(5))
    }

    // Any mouse or keyboard input wakes a sleeping display, so sleeping while the user's hand is
    // still on the mouse from clicking the button wakes it again at once. Wait for a quiet moment.
    private func sleepOnceInputIsIdle(giveUpAt deadline: Date) {
        let anyInput = CGEventType(rawValue: ~0)!
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        if idle < 0.3 && Date() < deadline {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
                self?.sleepOnceInputIsIdle(giveUpAt: deadline)
            }
            return
        }
        hidePanel()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["displaysleepnow"]
        try? task.run()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
