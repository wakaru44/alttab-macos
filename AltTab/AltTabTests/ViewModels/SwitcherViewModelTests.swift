import XCTest
@testable import AltTab

final class SwitcherViewModelTests: XCTestCase {
    var mockEnumerator: MockWindowEnumerator!
    var mockCapture: MockThumbnailCapture!
    var mockMRU: MockMRUTracker!
    var mockAccessibility: MockAccessibilityService!
    var viewModel: SwitcherViewModel!

    override func setUp() {
        super.setUp()
        mockEnumerator = MockWindowEnumerator()
        mockCapture = MockThumbnailCapture()
        mockMRU = MockMRUTracker()
        mockAccessibility = MockAccessibilityService()
        let activator = WindowActivator(accessibilityService: mockAccessibility)
        viewModel = SwitcherViewModel(
            windowEnumerator: mockEnumerator,
            thumbnailCapture: mockCapture,
            windowActivator: activator,
            mruTracker: mockMRU
        )
    }

    // MARK: - activate()

    func testActivate_loadsWindows() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        XCTAssertEqual(viewModel.windows.count, 3)
    }

    func testActivate_setsSelectedIndexTo1() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        XCTAssertEqual(viewModel.selectedIndex, 1)
    }

    func testActivate_setsSelectedIndexTo0_whenOneWindow() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 1)
        viewModel.activate()
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    func testActivate_setsIsActiveTrue() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 2)
        viewModel.activate()
        XCTAssertTrue(viewModel.isActive)
    }

    func testActivate_emptyWindows_doesNotActivate() {
        mockEnumerator.stubbedWindows = []
        viewModel.activate()
        XCTAssertFalse(viewModel.isActive)
    }

    func testActivate_callsOnUpdate() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 2)
        var updateCount = 0
        viewModel.onUpdate = { updateCount += 1 }
        viewModel.activate()
        XCTAssertGreaterThanOrEqual(updateCount, 1)
    }

    func testActivate_capturesThumbnails() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 2)
        viewModel.activate()
        XCTAssertEqual(mockCapture.captureCallCount, 1)
    }

    // MARK: - cycleNext()

    func testCycleNext_incrementsIndex() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        let initial = viewModel.selectedIndex
        viewModel.cycleNext()
        XCTAssertEqual(viewModel.selectedIndex, initial + 1)
    }

    func testCycleNext_wrapsToZero() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        viewModel.selectWindow(at: 2)
        viewModel.cycleNext()
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    func testCycleNext_emptyWindows_noChange() {
        viewModel.cycleNext()
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    // MARK: - cyclePrevious()

    func testCyclePrevious_decrementsIndex() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        viewModel.selectWindow(at: 2)
        viewModel.cyclePrevious()
        XCTAssertEqual(viewModel.selectedIndex, 1)
    }

    func testCyclePrevious_wrapsToLast() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        viewModel.selectWindow(at: 0)
        viewModel.cyclePrevious()
        XCTAssertEqual(viewModel.selectedIndex, 2)
    }

    // MARK: - confirm()

    func testConfirm_promotesWindowInMRU() {
        let windows = WindowInfoFactory.makeList(count: 3)
        mockEnumerator.stubbedWindows = windows
        viewModel.activate()
        let selectedWindow = viewModel.windows[viewModel.selectedIndex]
        viewModel.confirm()
        XCTAssertTrue(mockMRU.promoteToFrontCalls.contains(selectedWindow.windowID))
    }

    func testConfirm_deactivates() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 2)
        viewModel.activate()
        viewModel.confirm()
        XCTAssertFalse(viewModel.isActive)
    }

    func testConfirm_emptyWindows_cancels() {
        viewModel.confirm()
        XCTAssertFalse(viewModel.isActive)
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    // MARK: - cancel()

    func testCancel_resetsState() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        viewModel.cancel()
        XCTAssertFalse(viewModel.isActive)
        XCTAssertTrue(viewModel.windows.isEmpty)
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    func testCancel_callsOnUpdate() {
        var updateCalled = false
        viewModel.onUpdate = { updateCalled = true }
        viewModel.cancel()
        XCTAssertTrue(updateCalled)
    }

    // MARK: - selectWindow(at:)

    func testSelectWindow_validIndex_updatesSelection() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        viewModel.selectWindow(at: 2)
        XCTAssertEqual(viewModel.selectedIndex, 2)
    }

    func testSelectWindow_negativeIndex_noChange() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        let before = viewModel.selectedIndex
        viewModel.selectWindow(at: -1)
        XCTAssertEqual(viewModel.selectedIndex, before)
    }

    func testSelectWindow_outOfBounds_noChange() {
        mockEnumerator.stubbedWindows = WindowInfoFactory.makeList(count: 3)
        viewModel.activate()
        let before = viewModel.selectedIndex
        viewModel.selectWindow(at: 10)
        XCTAssertEqual(viewModel.selectedIndex, before)
    }
}
