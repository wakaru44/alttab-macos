import Cocoa

final class ThumbnailRepository: ThumbnailCaching {

    private let cache = NSCache<NSNumber, NSImage>()

    func thumbnail(for windowID: CGWindowID) -> NSImage? {
        cache.object(forKey: NSNumber(value: windowID))
    }

    func store(thumbnail: NSImage, for windowID: CGWindowID) {
        cache.setObject(thumbnail, forKey: NSNumber(value: windowID))
    }

    func clearAll() {
        cache.removeAllObjects()
    }
}
