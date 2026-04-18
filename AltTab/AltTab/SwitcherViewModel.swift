import Cocoa

final class SwitcherViewModel {

    // MARK: - Dependencies (all protocol-typed)

    private let windowEnumerator: WindowEnumerating
    private let thumbnailCapture: ThumbnailCapturing
    private let windowActivator: WindowActivator
    private let mruTracker: MRUTracking

    // MARK: - State

    private(set) var windows: [WindowInfo] = []
    private(set) var selectedIndex: Int = 0
    private(set) var isActive: Bool = false

    /// Called when window list or selection changes. View should refresh.
    var onUpdate: (() -> Void)?

    // MARK: - Init

    init(windowEnumerator: WindowEnumerating,
         thumbnailCapture: ThumbnailCapturing,
         windowActivator: WindowActivator,
         mruTracker: MRUTracking) {
        self.windowEnumerator = windowEnumerator
        self.thumbnailCapture = thumbnailCapture
        self.windowActivator = windowActivator
        self.mruTracker = mruTracker
    }

    // MARK: - Actions

    func activate() {
        windows = windowEnumerator.enumerateWindows()
        guard !windows.isEmpty else { return }
        selectedIndex = min(1, windows.count - 1)
        isActive = true
        onUpdate?()

        thumbnailCapture.captureThumbnails(for: windows) { [weak self] updated in
            guard let self = self, self.isActive else { return }
            self.windows = updated
            DispatchQueue.main.async { self.onUpdate?() }
        }
    }

    func cycleNext() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
        onUpdate?()
    }

    func cyclePrevious() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
        onUpdate?()
    }

    func confirm() {
        guard isActive, !windows.isEmpty, selectedIndex < windows.count else {
            cancel()
            return
        }
        let window = windows[selectedIndex]
        cancel()
        windowActivator.activate(window: window)
        mruTracker.promoteToFront(windowID: window.windowID)
    }

    func cancel() {
        isActive = false
        windows = []
        selectedIndex = 0
        onUpdate?()
    }

    func selectWindow(at index: Int) {
        guard index >= 0, index < windows.count else { return }
        selectedIndex = index
        onUpdate?()
    }
}
