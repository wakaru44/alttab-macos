import Cocoa
import ApplicationServices

final class WindowActivator {

    private let accessibilityService: AccessibilityProviding

    init(accessibilityService: AccessibilityProviding) {
        self.accessibilityService = accessibilityService
    }

    func activate(window: WindowInfo) {
        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else { return }

        // 1. Unminimize if needed
        if window.isMinimized {
            unminimize(window: window)
        }

        // 2. Activate the owning application
        app.activate(options: [.activateIgnoringOtherApps])

        // 3. Raise the specific window via AXUIElement
        raiseWindow(window: window)
    }

    // MARK: - Unminimize

    private func unminimize(window: WindowInfo) {
        let axWindows = accessibilityService.axWindows(for: window.ownerPID)

        for axWindow in axWindows {
            guard let wid = accessibilityService.windowID(for: axWindow),
                  wid == window.windowID else { continue }
            accessibilityService.setMinimized(axWindow, value: false)
            break
        }
    }

    // MARK: - Raise Window

    private func raiseWindow(window: WindowInfo) {
        let axWindows = accessibilityService.axWindows(for: window.ownerPID)

        // Try to match by CGWindowID first
        for axWindow in axWindows {
            guard let wid = accessibilityService.windowID(for: axWindow),
                  wid == window.windowID else { continue }
            accessibilityService.raiseWindow(axWindow)
            accessibilityService.setMainWindow(axWindow)
            return
        }

        // Fallback: match by title
        for axWindow in axWindows {
            guard let title = accessibilityService.windowTitle(for: axWindow),
                  title == window.windowTitle, !title.isEmpty else { continue }
            accessibilityService.raiseWindow(axWindow)
            accessibilityService.setMainWindow(axWindow)
            return
        }

        // Last resort: raise the first window
        if let firstWindow = axWindows.first {
            accessibilityService.raiseWindow(firstWindow)
            accessibilityService.setMainWindow(firstWindow)
        }
    }
}
