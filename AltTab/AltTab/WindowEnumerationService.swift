import Cocoa
import ApplicationServices

final class WindowEnumerationService: WindowEnumerating {

    private let accessibilityService: AccessibilityProviding
    private let mruTracker: MRUTracking
    private let selfBundleID = Bundle.main.bundleIdentifier ?? ""

    init(accessibilityService: AccessibilityProviding, mruTracker: MRUTracking) {
        self.accessibilityService = accessibilityService
        self.mruTracker = mruTracker
    }

    func enumerateWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []
        var seenIDs = Set<CGWindowID>()

        // 1. On-screen windows from CGWindowList
        if let infoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] {
            for info in infoList {
                guard let window = parseWindowInfo(info, isMinimized: false) else { continue }
                guard !seenIDs.contains(window.windowID) else { continue }
                seenIDs.insert(window.windowID)
                windows.append(window)
            }
        }

        // 2. Minimized windows via AXUIElement
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }
        for app in runningApps {
            let axWindows = accessibilityService.axWindows(for: app.processIdentifier)
            for axWindow in axWindows {
                guard accessibilityService.isMinimized(axWindow) else { continue }
                guard let windowID = accessibilityService.windowID(for: axWindow),
                      !seenIDs.contains(windowID) else { continue }
                seenIDs.insert(windowID)

                let title = accessibilityService.windowTitle(for: axWindow) ?? ""
                windows.append(WindowInfo(
                    windowID: windowID,
                    ownerPID: app.processIdentifier,
                    ownerName: app.localizedName ?? "Unknown",
                    windowTitle: title,
                    bounds: .zero,
                    isMinimized: true,
                    thumbnail: nil
                ))
            }
        }

        // 3. Remove own windows
        let selfPID = ProcessInfo.processInfo.processIdentifier
        windows.removeAll { $0.ownerName == "AltTab" || $0.ownerPID == selfPID }

        // 4. Sort by MRU (visible before minimized)
        mruTracker.prune(validIDs: Set(windows.map { $0.windowID }))
        let mruOrder = mruTracker.orderedIDs()
        windows.sort { a, b in
            if a.isMinimized != b.isMinimized { return !a.isMinimized }
            let idxA = mruOrder.firstIndex(of: a.windowID) ?? Int.max
            let idxB = mruOrder.firstIndex(of: b.windowID) ?? Int.max
            return idxA < idxB
        }

        return windows
    }

    // MARK: - Private

    private func parseWindowInfo(_ info: [String: Any], isMinimized: Bool) -> WindowInfo? {
        guard let windowID = info[kCGWindowNumber as String] as? CGWindowID,
              let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
              let ownerName = info[kCGWindowOwnerName as String] as? String,
              let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
              let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
              let x = boundsDict["X"], let y = boundsDict["Y"],
              let w = boundsDict["Width"], let h = boundsDict["Height"],
              w > 0, h > 0 else { return nil }

        var title = info[kCGWindowName as String] as? String ?? ""
        if title.isEmpty {
            title = axWindowTitle(for: windowID, pid: ownerPID)
        }

        return WindowInfo(
            windowID: windowID, ownerPID: ownerPID, ownerName: ownerName,
            windowTitle: title, bounds: CGRect(x: x, y: y, width: w, height: h),
            isMinimized: isMinimized, thumbnail: nil
        )
    }

    private func axWindowTitle(for targetID: CGWindowID, pid: pid_t) -> String {
        for axWindow in accessibilityService.axWindows(for: pid) {
            guard let wid = accessibilityService.windowID(for: axWindow),
                  wid == targetID else { continue }
            return accessibilityService.windowTitle(for: axWindow) ?? ""
        }
        return ""
    }
}
