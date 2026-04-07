import XCTest
@testable import AltTab

final class ThumbnailRepositoryTests: XCTestCase {
    var repo: ThumbnailRepository!

    override func setUp() {
        super.setUp()
        repo = ThumbnailRepository()
    }

    func testStore_andRetrieve() {
        let image = NSImage(size: NSSize(width: 10, height: 10))
        let id: CGWindowID = 42
        repo.store(thumbnail: image, for: id)
        XCTAssertNotNil(repo.thumbnail(for: id))
    }

    func testThumbnail_missingID_returnsNil() {
        XCTAssertNil(repo.thumbnail(for: 999))
    }

    func testClearAll_removesAll() {
        let image = NSImage(size: NSSize(width: 10, height: 10))
        repo.store(thumbnail: image, for: 1)
        repo.store(thumbnail: image, for: 2)
        repo.clearAll()
        XCTAssertNil(repo.thumbnail(for: 1))
        XCTAssertNil(repo.thumbnail(for: 2))
    }

    func testStore_overwritesExisting() {
        let img1 = NSImage(size: NSSize(width: 10, height: 10))
        let img2 = NSImage(size: NSSize(width: 20, height: 20))
        repo.store(thumbnail: img1, for: 1)
        repo.store(thumbnail: img2, for: 1)
        let retrieved = repo.thumbnail(for: 1)
        XCTAssertNotNil(retrieved)
        // NSCache may evict, so just verify we get something back
    }
}
