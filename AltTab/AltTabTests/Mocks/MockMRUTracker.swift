import Cocoa
@testable import AltTab

final class MockMRUTracker: MRUTracking {
    var mruOrder: [CGWindowID] = []
    var promoteToFrontCalls: [CGWindowID] = []
    var pruneCalls: [Set<CGWindowID>] = []

    func promoteToFront(windowID: CGWindowID) {
        promoteToFrontCalls.append(windowID)
        mruOrder.removeAll { $0 == windowID }
        mruOrder.insert(windowID, at: 0)
    }

    func orderedIDs() -> [CGWindowID] {
        mruOrder
    }

    func prune(validIDs: Set<CGWindowID>) {
        pruneCalls.append(validIDs)
        mruOrder.removeAll { !validIDs.contains($0) }
    }
}
