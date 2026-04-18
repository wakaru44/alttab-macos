import XCTest
@testable import AltTab

final class WindowEnumerationServiceTests: XCTestCase {
    var mockAccessibility: MockAccessibilityService!
    var mockMRU: MockMRUTracker!
    var service: WindowEnumerationService!

    override func setUp() {
        super.setUp()
        mockAccessibility = MockAccessibilityService()
        mockMRU = MockMRUTracker()
        service = WindowEnumerationService(accessibilityService: mockAccessibility, mruTracker: mockMRU)
    }

    // MARK: - Self-exclusion

    func testEnumerateWindows_excludesSelf() {
        let windows = service.enumerateWindows()
        XCTAssertTrue(windows.allSatisfy { $0.ownerName != "AltTab" })
    }

    func testEnumerateWindows_excludesSelfPID() {
        let selfPID = ProcessInfo.processInfo.processIdentifier
        let windows = service.enumerateWindows()
        XCTAssertTrue(windows.allSatisfy { $0.ownerPID != selfPID })
    }

    // MARK: - Sorting (visible before minimized)

    func testEnumerateWindows_visibleBeforeMinimized() {
        // Any minimized windows returned should come after all visible windows
        let windows = service.enumerateWindows()
        if let firstMinimized = windows.firstIndex(where: { $0.isMinimized }),
           let lastVisible = windows.lastIndex(where: { !$0.isMinimized }) {
            XCTAssertTrue(lastVisible < firstMinimized,
                         "All visible windows should come before minimized windows")
        }
        // If no minimized or no visible, sorting is trivially correct
    }

    // MARK: - MRU integration

    func testEnumerateWindows_prunesMRUTracker() {
        _ = service.enumerateWindows()
        XCTAssertEqual(mockMRU.pruneCalls.count, 1, "Should call prune exactly once")
    }

    func testEnumerateWindows_prunesWithReturnedWindowIDs() {
        let windows = service.enumerateWindows()
        let windowIDs = Set(windows.map { $0.windowID })
        if let prunedIDs = mockMRU.pruneCalls.first {
            XCTAssertEqual(prunedIDs, windowIDs, "Pruned IDs should match returned window IDs")
        }
    }

    // MARK: - Window filtering (layer/bounds validated by CGWindowList)

    func testEnumerateWindows_allWindowsHaveValidBoundsOrAreMinimized() {
        let windows = service.enumerateWindows()
        for window in windows {
            if !window.isMinimized {
                XCTAssertTrue(window.bounds.width > 0 && window.bounds.height > 0,
                             "Visible window \(window.windowID) should have positive bounds")
            }
        }
    }

    func testEnumerateWindows_noDuplicateWindowIDs() {
        let windows = service.enumerateWindows()
        let ids = windows.map { $0.windowID }
        XCTAssertEqual(ids.count, Set(ids).count, "Should have no duplicate window IDs")
    }
}
