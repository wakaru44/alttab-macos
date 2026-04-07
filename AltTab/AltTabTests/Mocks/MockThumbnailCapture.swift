import Cocoa
@testable import AltTab

final class MockThumbnailCapture: ThumbnailCapturing {
    var stubbedResult: [WindowInfo] = []
    var captureCallCount = 0
    var lastCapturedWindows: [WindowInfo]?

    func captureThumbnails(for windows: [WindowInfo], completion: @escaping ([WindowInfo]) -> Void) {
        captureCallCount += 1
        lastCapturedWindows = windows
        completion(stubbedResult.isEmpty ? windows : stubbedResult)
    }
}
