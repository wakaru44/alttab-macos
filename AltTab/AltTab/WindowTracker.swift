import Cocoa
import ApplicationServices

final class WindowTracker: WindowTrackingService {

    private let accessibilityService: AccessibilityProviding
    private let mruTracker: MRUTracking
    private var axObservers: [pid_t: AXObserver] = [:]

    init(accessibilityService: AccessibilityProviding, mruTracker: MRUTracking) {
        self.accessibilityService = accessibilityService
        self.mruTracker = mruTracker
    }

    deinit {
        stopTracking()
    }

    // MARK: - WindowTrackingService

    func startTracking() {
        observeAppActivation()
        observeAppLifecycle()
        installAXObserversForRunningApps()
    }

    func stopTracking() {
        removeAllAXObservers()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - App Activation (TRACK-04, TRACK-05)

    private func observeAppActivation() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[
                    NSWorkspace.applicationUserInfoKey
                  ] as? NSRunningApplication else { return }
            self.promoteAppFocusedWindow(pid: app.processIdentifier)
        }
    }

    private func promoteAppFocusedWindow(pid: pid_t) {
        guard let focusedWindow = accessibilityService.focusedWindow(for: pid),
              let windowID = accessibilityService.windowID(for: focusedWindow) else { return }
        mruTracker.promoteToFront(windowID: windowID)
    }

    // MARK: - App Lifecycle (TRACK-02, TRACK-03, TRACK-08)

    private func observeAppLifecycle() {
        let center = NSWorkspace.shared.notificationCenter

        center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.activationPolicy == .regular else { return }
            self?.installAXObserver(for: app.processIdentifier)
        }

        center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[
                NSWorkspace.applicationUserInfoKey
            ] as? NSRunningApplication else { return }
            self?.removeAXObserver(for: app.processIdentifier)
        }
    }

    // MARK: - AXObserver (TRACK-01, TRACK-06)

    private func installAXObserversForRunningApps() {
        let selfPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != selfPID
        }
        for app in apps {
            installAXObserver(for: app.processIdentifier)
        }
    }

    private func installAXObserver(for pid: pid_t) {
        guard axObservers[pid] == nil else { return }

        var observer: AXObserver?
        guard AXObserverCreate(pid, windowTrackerAXCallback, &observer) == .success,
              let observer = observer else { return }

        let axApp = AXUIElementCreateApplication(pid)
        AXObserverAddNotification(observer, axApp,
                                  kAXFocusedWindowChangedNotification as CFString,
                                  Unmanaged.passUnretained(self).toOpaque())

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        axObservers[pid] = observer
    }

    private func removeAXObserver(for pid: pid_t) {
        guard let observer = axObservers.removeValue(forKey: pid) else { return }
        let axApp = AXUIElementCreateApplication(pid)
        AXObserverRemoveNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
    }

    private func removeAllAXObservers() {
        for pid in axObservers.keys {
            removeAXObserver(for: pid)
        }
    }

    // MARK: - AXObserver Callback Handler

    fileprivate func handleFocusedWindowChanged(_ element: AXUIElement) {
        guard let windowID = accessibilityService.windowID(for: element) else { return }
        mruTracker.promoteToFront(windowID: windowID)
    }
}

// MARK: - C Callback

private func windowTrackerAXCallback(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ userInfo: UnsafeMutableRawPointer?
) {
    guard let userInfo = userInfo else { return }
    let tracker = Unmanaged<WindowTracker>.fromOpaque(userInfo).takeUnretainedValue()
    tracker.handleFocusedWindowChanged(element)
}
