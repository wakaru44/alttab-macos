import Cocoa

final class MRUTracker: MRUTracking {

    private var mruOrder: [CGWindowID] = []

    init() {
        seedFromStackingOrder()
    }

    // MARK: - MRUTracking

    func promoteToFront(windowID: CGWindowID) {
        mruOrder.removeAll { $0 == windowID }
        mruOrder.insert(windowID, at: 0)
    }

    func orderedIDs() -> [CGWindowID] {
        mruOrder
    }

    func prune(validIDs: Set<CGWindowID>) {
        mruOrder.removeAll { !validIDs.contains($0) }
        for id in validIDs where !mruOrder.contains(id) {
            mruOrder.append(id)
        }
    }

    // MARK: - Private

    private func seedFromStackingOrder() {
        guard let infoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return }

        mruOrder = infoList.compactMap { info -> CGWindowID? in
            guard let id = info[kCGWindowNumber as String] as? CGWindowID,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"], let height = bounds["Height"],
                  width > 0, height > 0 else { return nil }
            return id
        }
    }
}
