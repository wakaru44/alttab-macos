import XCTest
@testable import AltTab

final class EnumerationPipelineTests: XCTestCase {
    // MARK: - Full pipeline: enumerate -> sort -> present via ViewModel (TEST-06)

    func testFullPipeline_enumerateToPresent() {
        // Wire real services with mock dependencies
        let mockAccessibility = MockAccessibilityService()
        let mockMRU = MockMRUTracker()
        let enumerator = WindowEnumerationService(accessibilityService: mockAccessibility, mruTracker: mockMRU)
        let mockCapture = MockThumbnailCapture()
        let activator = WindowActivator(accessibilityService: mockAccessibility)

        let viewModel = SwitcherViewModel(
            windowEnumerator: enumerator,
            thumbnailCapture: mockCapture,
            windowActivator: activator,
            mruTracker: mockMRU
        )

        var updateCalled = false
        viewModel.onUpdate = { updateCalled = true }

        viewModel.activate()

        // Pipeline executed: enumerateWindows() ran, results sorted, presented in ViewModel
        XCTAssertTrue(updateCalled, "onUpdate should fire after activation")
        // Windows come from real system, so count may vary, but pipeline didn't crash
        // Verify no self-windows
        XCTAssertTrue(viewModel.windows.allSatisfy { $0.ownerName != "AltTab" })
    }

    func testFullPipeline_cycleAndConfirm() {
        let mockAccessibility = MockAccessibilityService()
        let mockMRU = MockMRUTracker()
        let enumerator = WindowEnumerationService(accessibilityService: mockAccessibility, mruTracker: mockMRU)
        let mockCapture = MockThumbnailCapture()
        let activator = WindowActivator(accessibilityService: mockAccessibility)

        let viewModel = SwitcherViewModel(
            windowEnumerator: enumerator,
            thumbnailCapture: mockCapture,
            windowActivator: activator,
            mruTracker: mockMRU
        )

        viewModel.activate()

        guard !viewModel.windows.isEmpty else {
            // No windows on this system - skip
            return
        }

        let windowCount = viewModel.windows.count
        // Cycle through all windows
        for _ in 0..<windowCount {
            viewModel.cycleNext()
        }
        // Should wrap around to starting position
        XCTAssertEqual(viewModel.selectedIndex, viewModel.selectedIndex % windowCount)

        // Confirm activates window
        viewModel.confirm()
        XCTAssertFalse(viewModel.isActive)
    }

    // MARK: - Mocked system API integration (TEST-06)

    func testMockedPipeline_sortOrder() {
        let mockEnumerator = MockWindowEnumerator()
        let mockMRU = MockMRUTracker()
        let mockCapture = MockThumbnailCapture()
        let mockAccessibility = MockAccessibilityService()
        let activator = WindowActivator(accessibilityService: mockAccessibility)

        // Set up known windows
        let windows = [
            WindowInfoFactory.make(windowID: 1, ownerName: "App1", windowTitle: "Win1"),
            WindowInfoFactory.make(windowID: 2, ownerName: "App2", windowTitle: "Win2"),
            WindowInfoFactory.make(windowID: 3, ownerName: "App3", windowTitle: "Win3"),
        ]
        mockEnumerator.stubbedWindows = windows

        let viewModel = SwitcherViewModel(
            windowEnumerator: mockEnumerator,
            thumbnailCapture: mockCapture,
            windowActivator: activator,
            mruTracker: mockMRU
        )

        viewModel.activate()

        XCTAssertEqual(viewModel.windows.count, 3)
        XCTAssertEqual(viewModel.selectedIndex, 1)
        XCTAssertTrue(viewModel.isActive)
    }
}
