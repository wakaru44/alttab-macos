import Cocoa
import ApplicationServices
import ScreenCaptureKit

// MARK: - Accessibility

protocol AccessibilityProviding: AnyObject {
    func axWindows(for pid: pid_t) -> [AXUIElement]
    func focusedWindow(for pid: pid_t) -> AXUIElement?
    func windowID(for element: AXUIElement) -> CGWindowID?
    func windowTitle(for element: AXUIElement) -> String?
    func isMinimized(_ element: AXUIElement) -> Bool
    func setMinimized(_ element: AXUIElement, value: Bool)
    func raiseWindow(_ element: AXUIElement)
    func setMainWindow(_ element: AXUIElement)
}

// MARK: - Window Enumeration

protocol WindowEnumerating: AnyObject {
    func enumerateWindows() -> [WindowInfo]
}

// MARK: - Thumbnail Caching

protocol ThumbnailCaching: AnyObject {
    func thumbnail(for windowID: CGWindowID) -> NSImage?
    func store(thumbnail: NSImage, for windowID: CGWindowID)
    func clearAll()
}

// MARK: - Thumbnail Capturing

protocol ThumbnailCapturing: AnyObject {
    func captureThumbnails(for windows: [WindowInfo], completion: @escaping ([WindowInfo]) -> Void)
}

// MARK: - MRU Tracking

protocol MRUTracking: AnyObject {
    func promoteToFront(windowID: CGWindowID)
    func orderedIDs() -> [CGWindowID]
    func prune(validIDs: Set<CGWindowID>)
}

// MARK: - Window Tracking (Observer lifecycle)

protocol WindowTrackingService: AnyObject {
    func startTracking()
    func stopTracking()
}
