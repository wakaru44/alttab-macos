import Cocoa
import ApplicationServices

final class AccessibilityService: AccessibilityProviding {

    func axWindows(for pid: pid_t) -> [AXUIElement] {
        let axApp = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return [] }
        return windows
    }

    func focusedWindow(for pid: pid_t) -> AXUIElement? {
        let axApp = AXUIElementCreateApplication(pid)
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedRef) == .success else { return nil }
        return (focusedRef as! AXUIElement)
    }

    func windowID(for element: AXUIElement) -> CGWindowID? {
        var wid: CGWindowID = 0
        let result = _AXUIElementGetWindow(element, &wid)
        return result == .success && wid != 0 ? wid : nil
    }

    func windowTitle(for element: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef) == .success,
              let title = titleRef as? String, !title.isEmpty else { return nil }
        return title
    }

    func isMinimized(_ element: AXUIElement) -> Bool {
        var minimizedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &minimizedRef) == .success,
              let isMin = minimizedRef as? Bool else { return false }
        return isMin
    }

    func setMinimized(_ element: AXUIElement, value: Bool) {
        AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, value as CFTypeRef)
    }

    func raiseWindow(_ element: AXUIElement) {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
    }

    func setMainWindow(_ element: AXUIElement) {
        AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, true as CFTypeRef)
    }
}
