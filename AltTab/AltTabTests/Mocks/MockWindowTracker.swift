@testable import AltTab

final class MockWindowTracker: WindowTrackingService {
    var startTrackingCalled = false
    var stopTrackingCalled = false

    func startTracking() {
        startTrackingCalled = true
    }

    func stopTracking() {
        stopTrackingCalled = true
    }
}
