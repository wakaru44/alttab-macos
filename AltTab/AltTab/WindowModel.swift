import Cocoa
import ApplicationServices

// MARK: - WindowInfo

struct WindowInfo {
    let windowID: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let windowTitle: String
    let bounds: CGRect
    let isMinimized: Bool
    var thumbnail: NSImage?

    var appIcon: NSImage {
        NSRunningApplication(processIdentifier: ownerPID)?.icon
            ?? NSImage(named: NSImage.applicationIconName) ?? NSImage()
    }
}

// MARK: - Private SPI

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(
    _ element: AXUIElement,
    _ windowID: UnsafeMutablePointer<CGWindowID>
) -> AXError
