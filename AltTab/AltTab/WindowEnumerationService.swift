import Cocoa
import ApplicationServices

final class WindowEnumerationService: WindowEnumerating {

    private let accessibilityService: AccessibilityProviding
    private let mruTracker: MRUTracking
    private let selfPID = ProcessInfo.processInfo.processIdentifier

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

        // 3. Remove own windows (PID-only check, no fragile string matching)
        windows.removeAll { $0.ownerPID == selfPID }

        // 4. Sort by MRU (visible before minimized)
        mruTracker.prune(validIDs: Set(windows.map { $0.windowID }))
        let mruOrder = mruTracker.orderedIDs()
        windows.sort { lhs, rhs in
            if lhs.isMinimized != rhs.isMinimized { return !lhs.isMinimized }
            let idxA = mruOrder.firstIndex(of: lhs.windowID) ?? Int.max
            let idxB = mruOrder.firstIndex(of: rhs.windowID) ?? Int.max
            return idxA < idxB
        }

        return windows
    }

    // MARK: - Private

    private func parseWindowInfo(_ info: [String: Any], isMinimized: Bool) -> WindowInfo? {
        guard let windowID = info[kCGWindowNumber as String] as? CGWindowID,
              let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
              let ownerName = info[kCGWindowOwnerName as String] as? String else {
            return nil
        }

        // Layer 0 = normal windows. Filter non-zero layers (system chrome, menubar, dock, etc.)
        guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else {
            NSLog("WindowEnum: Filtered windowID=\(windowID) owner=\(ownerName) reason=layer(\(info[kCGWindowLayer as String] as? Int ?? -1))")
            return nil
        }

        guard let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
              let posX = boundsDict["X"], let posY = boundsDict["Y"],
              let width = boundsDict["Width"], let height = boundsDict["Height"],
              width > 0, height > 0 else {
            NSLog("WindowEnum: Filtered windowID=\(windowID) owner=\(ownerName) reason=bounds")
            return nil
        }

        var title = info[kCGWindowName as String] as? String ?? ""
        if title.isEmpty {
            title = axWindowTitle(for: windowID, pid: ownerPID)
        }

        return WindowInfo(
            windowID: windowID, ownerPID: ownerPID, ownerName: ownerName,
            windowTitle: title, bounds: CGRect(x: posX, y: posY, width: width, height: height),
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
