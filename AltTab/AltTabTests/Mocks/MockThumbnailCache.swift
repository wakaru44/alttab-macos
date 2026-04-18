import Cocoa
@testable import AltTab

final class MockThumbnailCache: ThumbnailCaching {
    var cache: [CGWindowID: NSImage] = [:]
    var clearAllCalled = false

    func thumbnail(for windowID: CGWindowID) -> NSImage? {
        cache[windowID]
    }

    func store(thumbnail: NSImage, for windowID: CGWindowID) {
        cache[windowID] = thumbnail
    }

    func clearAll() {
        cache.removeAll()
        clearAllCalled = true
    }
}
