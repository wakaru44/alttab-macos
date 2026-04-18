import Cocoa
@testable import AltTab

enum WindowInfoFactory {
    static func make(
        windowID: CGWindowID = 1,
        ownerPID: pid_t = 100,
        ownerName: String = "TestApp",
        windowTitle: String = "Test Window",
        bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600),
        isMinimized: Bool = false,
        thumbnail: NSImage? = nil
    ) -> WindowInfo {
        WindowInfo(
            windowID: windowID,
            ownerPID: ownerPID,
            ownerName: ownerName,
            windowTitle: windowTitle,
            bounds: bounds,
            isMinimized: isMinimized,
            thumbnail: thumbnail
        )
    }

    /// Create N distinct windows with sequential IDs
    static func makeList(count: Int, ownerName: String = "TestApp", ownerPID: pid_t = 100) -> [WindowInfo] {
        (1...count).map { i in
            make(
                windowID: CGWindowID(i),
                ownerPID: ownerPID,
                ownerName: ownerName,
                windowTitle: "Window \(i)"
            )
        }
    }
}
