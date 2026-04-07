import Cocoa
import ApplicationServices
@testable import AltTab

final class MockAccessibilityService: AccessibilityProviding {
    var stubbedAXWindows: [pid_t: [AXUIElement]] = [:]
    var stubbedFocusedWindow: [pid_t: AXUIElement] = [:]

    // Use arrays of tuples since AXUIElement is not Hashable
    private var windowIDMap: [(AXUIElement, CGWindowID)] = []
    private var windowTitleMap: [(AXUIElement, String)] = []
    private var minimizedElements: [AXUIElement] = []

    // Spy tracking
    var raiseWindowCalled = false
    var setMainWindowCalled = false
    var setMinimizedCalls: [(AXUIElement, Bool)] = []

    func stubWindowID(_ id: CGWindowID, for element: AXUIElement) {
        windowIDMap.append((element, id))
    }

    func stubWindowTitle(_ title: String, for element: AXUIElement) {
        windowTitleMap.append((element, title))
    }

    func stubMinimized(_ element: AXUIElement) {
        minimizedElements.append(element)
    }

    func axWindows(for pid: pid_t) -> [AXUIElement] {
        stubbedAXWindows[pid] ?? []
    }

    func focusedWindow(for pid: pid_t) -> AXUIElement? {
        stubbedFocusedWindow[pid]
    }

    func windowID(for element: AXUIElement) -> CGWindowID? {
        windowIDMap.first(where: { CFEqual($0.0, element) })?.1
    }

    func windowTitle(for element: AXUIElement) -> String? {
        windowTitleMap.first(where: { CFEqual($0.0, element) })?.1
    }

    func isMinimized(_ element: AXUIElement) -> Bool {
        minimizedElements.contains(where: { CFEqual($0, element) })
    }

    func setMinimized(_ element: AXUIElement, value: Bool) {
        setMinimizedCalls.append((element, value))
    }

    func raiseWindow(_ element: AXUIElement) {
        raiseWindowCalled = true
    }

    func setMainWindow(_ element: AXUIElement) {
        setMainWindowCalled = true
    }
}
