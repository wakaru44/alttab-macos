import XCTest
import ApplicationServices
@testable import AltTab

final class WindowActivatorTests: XCTestCase {
    var mockAccessibility: MockAccessibilityService!
    var activator: WindowActivator!
    var validPID: pid_t!

    override func setUp() {
        super.setUp()
        mockAccessibility = MockAccessibilityService()
        activator = WindowActivator(accessibilityService: mockAccessibility)

        // Use the current process PID (guaranteed to exist)
        validPID = ProcessInfo.processInfo.processIdentifier
    }

    func testActivate_minimizedWindow_callsSetMinimizedFalse() {
        let window = WindowInfoFactory.make(windowID: 1, ownerPID: validPID, isMinimized: true)
        let axElement = AXUIElementCreateApplication(validPID)
        mockAccessibility.stubbedAXWindows[validPID] = [axElement]
        mockAccessibility.stubWindowID(1, for: axElement)

        activator.activate(window: window)

        XCTAssertTrue(mockAccessibility.setMinimizedCalls.contains(where: { _, value in value == false }))
    }

    func testActivate_callsRaiseWindow() {
        let window = WindowInfoFactory.make(windowID: 1, ownerPID: validPID)
        let axElement = AXUIElementCreateApplication(validPID)
        mockAccessibility.stubbedAXWindows[validPID] = [axElement]
        mockAccessibility.stubWindowID(1, for: axElement)

        activator.activate(window: window)

        XCTAssertTrue(mockAccessibility.raiseWindowCalled)
    }

    func testActivate_callsSetMainWindow() {
        let window = WindowInfoFactory.make(windowID: 1, ownerPID: validPID)
        let axElement = AXUIElementCreateApplication(validPID)
        mockAccessibility.stubbedAXWindows[validPID] = [axElement]
        mockAccessibility.stubWindowID(1, for: axElement)

        activator.activate(window: window)

        XCTAssertTrue(mockAccessibility.setMainWindowCalled)
    }
}
