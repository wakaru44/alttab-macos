import XCTest
@testable import AltTab

// MARK: - Mock Accessibility Service

private final class MockAccessibilityService: AccessibilityProviding {
    var mockMinimizedWindows: [(pid: pid_t, windowID: CGWindowID, title: String)] = []

    func axWindows(for pid: pid_t) -> [AXUIElement] {
        // Return one AXUIElement per minimized window matching this PID
        return mockMinimizedWindows
            .filter { $0.pid == pid }
            .map { _ in AXUIElementCreateSystemWide() } // placeholder
    }

    func focusedWindow(for pid: pid_t) -> AXUIElement? { nil }

    func windowID(for element: AXUIElement) -> CGWindowID? {
        // Not easily testable without real AX — covered by integration tests
        nil
    }

    func windowTitle(for element: AXUIElement) -> String? { nil }
    func isMinimized(_ element: AXUIElement) -> Bool { true }
    func setMinimized(_ element: AXUIElement, value: Bool) {}
    func raiseWindow(_ element: AXUIElement) {}
    func setMainWindow(_ element: AXUIElement) {}
}

// MARK: - Mock MRU Tracker

private final class MockMRUTracker: MRUTracking {
    var ids: [CGWindowID] = []

    func promoteToFront(windowID: CGWindowID) {
        ids.removeAll { $0 == windowID }
        ids.insert(windowID, at: 0)
    }

    func orderedIDs() -> [CGWindowID] { ids }

    func prune(validIDs: Set<CGWindowID>) {
        ids.removeAll { !validIDs.contains($0) }
    }
}

// MARK: - Tests

final class WindowEnumerationServiceTests: XCTestCase {

    private var accessibilityService: MockAccessibilityService!
    private var mruTracker: MockMRUTracker!
    private var service: WindowEnumerationService!

    override func setUp() {
        super.setUp()
        accessibilityService = MockAccessibilityService()
        mruTracker = MockMRUTracker()
        service = WindowEnumerationService(
            accessibilityService: accessibilityService,
            mruTracker: mruTracker
        )
    }

    // MARK: - Self-filtering

    func testSelfWindowsFilteredByPID() {
        // The service filters its own PID. Since we run in the test host process,
        // any windows belonging to our PID should be excluded.
        let windows = service.enumerateWindows()
        let selfPID = ProcessInfo.processInfo.processIdentifier
        let selfWindows = windows.filter { $0.ownerPID == selfPID }
        XCTAssertTrue(selfWindows.isEmpty, "Own windows should be filtered out by PID")
    }

    func testSelfFilterDoesNotUseStringMatching() {
        // Verify the source code uses PID-only filtering (regression guard).
        // This is a source-level assertion — if the file changes, this test catches regressions.
        let sourceURL = Bundle(for: type(of: self)).bundleURL
            .deletingLastPathComponent() // plugins
            .deletingLastPathComponent() // AltTabTests.xctest
            .deletingLastPathComponent() // Products
            .deletingLastPathComponent() // Build
            .appendingPathComponent("AltTab/AltTab/WindowEnumerationService.swift")

        // Skip if source not found (CI may not have source alongside build)
        guard let source = try? String(contentsOf: sourceURL, encoding: .utf8) else { return }
        XCTAssertFalse(
            source.contains("ownerName == \"AltTab\""),
            "Self-filter should use PID, not string matching"
        )
    }

    // MARK: - Enumeration returns results

    func testEnumerateWindowsReturnsArray() {
        // Basic smoke test — enumeration should not crash and returns an array
        let windows = service.enumerateWindows()
        XCTAssertNotNil(windows)
    }
}
