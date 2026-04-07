import XCTest
@testable import AltTab

final class MRUTrackerTests: XCTestCase {
    var tracker: MRUTracker!

    override func setUp() {
        super.setUp()
        tracker = MRUTracker()
    }

    // MARK: - promoteToFront

    func testPromoteToFront_newID_addsToFront() {
        let id: CGWindowID = 99991
        tracker.promoteToFront(windowID: id)
        XCTAssertEqual(tracker.orderedIDs().first, id)
    }

    func testPromoteToFront_existingID_movesToFront() {
        let id1: CGWindowID = 99991
        let id2: CGWindowID = 99992
        tracker.promoteToFront(windowID: id1)
        tracker.promoteToFront(windowID: id2)
        tracker.promoteToFront(windowID: id1)
        let ids = tracker.orderedIDs()
        let idx1 = ids.firstIndex(of: id1)!
        let idx2 = ids.firstIndex(of: id2)!
        XCTAssertTrue(idx1 < idx2)
    }

    func testPromoteToFront_duplicateCall_noDuplicates() {
        let id: CGWindowID = 99991
        tracker.promoteToFront(windowID: id)
        tracker.promoteToFront(windowID: id)
        let count = tracker.orderedIDs().filter { $0 == id }.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - prune

    func testPrune_removesInvalidIDs() {
        let id1: CGWindowID = 99991
        let id2: CGWindowID = 99992
        tracker.promoteToFront(windowID: id1)
        tracker.promoteToFront(windowID: id2)
        tracker.prune(validIDs: [id1])
        XCTAssertTrue(tracker.orderedIDs().contains(id1))
        XCTAssertFalse(tracker.orderedIDs().contains(id2))
    }

    func testPrune_addsNewValidIDs() {
        let existing: CGWindowID = 99991
        let newID: CGWindowID = 99992
        tracker.promoteToFront(windowID: existing)
        tracker.prune(validIDs: [existing, newID])
        XCTAssertTrue(tracker.orderedIDs().contains(newID))
    }

    func testPrune_newIDsAppendedAtEnd() {
        let existing: CGWindowID = 99991
        let newID: CGWindowID = 99992
        tracker.promoteToFront(windowID: existing)
        tracker.prune(validIDs: [existing, newID])
        let ids = tracker.orderedIDs()
        let existingIdx = ids.firstIndex(of: existing)!
        let newIdx = ids.firstIndex(of: newID)!
        XCTAssertTrue(existingIdx < newIdx)
    }

    // MARK: - orderedIDs

    func testOrderedIDs_reflectsPromotionOrder() {
        let ids: [CGWindowID] = [99991, 99992, 99993]
        for id in ids { tracker.promoteToFront(windowID: id) }
        // Last promoted should be first
        let ordered = tracker.orderedIDs()
        XCTAssertEqual(ordered.first, 99993)
    }
}
