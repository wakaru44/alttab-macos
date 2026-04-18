@testable import AltTab

final class MockWindowEnumerator: WindowEnumerating {
    var stubbedWindows: [WindowInfo] = []
    var enumerateWindowsCallCount = 0

    func enumerateWindows() -> [WindowInfo] {
        enumerateWindowsCallCount += 1
        return stubbedWindows
    }
}
