# Code Conventions

## Language & Style

**Swift Version**: 5.9+
- Modern Swift idioms (async/await, property wrappers)
- Strict concurrency checking disabled (legacy GCD + new async)

**File Organization**: One class per file (mostly)
- File name matches primary type: `HotkeyManager.swift` → `class HotkeyManager`
- Exception: Helper types may coexist with primary type

## Naming Conventions

### Files & Types
- **PascalCase** for files: `WindowCapture.swift`, `ThumbnailView.swift`
- **PascalCase** for classes/structs/enums: `class SwitcherPanel`, `struct WindowInfo`
- **PascalCase** for protocols: `protocol HotkeyDelegate`

### Functions & Variables
- **camelCase** for functions: `func captureWindowThumbnail()`
- **camelCase** for variables: `let windowID`, `var isVisible`
- **Verb-first method names**: `activateWindow()`, `showSwitcher()`, `hidePanel()`
- **Boolean predicates**: `isMinimized`, `hasPermission`, `canCapture`

### Constants
- **camelCase** for local constants: `let defaultWindowSize = 200`
- **Static constants**: Same as variables (no screaming snake case)

### Private Members
- **No underscore prefix**: Use `private` keyword instead
  - `private var cache` (not `private var _cache`)

## Code Structure

### File Header
- No file headers or copyright comments
- No author attribution
- Files start directly with imports

### Imports
```swift
import Cocoa
import ApplicationServices
import ScreenCaptureKit
```
- Foundation/AppKit via `import Cocoa`
- Explicit imports for system frameworks
- No wildcard imports

### MARK Comments
Extensive use of `// MARK: -` for section organization:

```swift
// MARK: - Lifecycle
init() { }
deinit { }

// MARK: - Public Methods
func showSwitcher() { }

// MARK: - Private Helpers
private func updateWindowList() { }

// MARK: - Hotkey Callbacks
private func handleHotkey() { }
```

**Sections typically include**:
- Lifecycle (init/deinit)
- Properties
- Public Methods
- Private Helpers
- Delegate Methods
- Callbacks
- UI Updates

## Error Handling

### Guard Statements
Primary error handling pattern:
```swift
guard let window = getActiveWindow() else {
    NSLog("Failed to get active window")
    return
}
```

**Style**:
- Early returns via `guard` (not nested `if let`)
- Log errors with `NSLog()` (not `print()` or `os.log`)
- No throwing functions (no `throws` keyword used)
- No `Result<T, E>` types (not used in codebase)

### Optional Handling
```swift
// Preferred: Optional binding
if let image = captureImage() {
    applyImage(image)
}

// Preferred: Nil coalescing
let title = window.title ?? "Untitled"

// Avoid: Force unwrapping (rarely used)
let value = dict["key"]!  // Only when guaranteed non-nil
```

### Logging
**NSLog() everywhere** (not os.log or print):
```swift
NSLog("Thumbnail captured for window \(windowID)")
NSLog("Permission denied: \(error)")
```

**Reason**: `os.log` writes to unified logging (not stderr), invisible in custom log files

**Debug Log File**: `/tmp/alttab-debug.log` (stdout/stderr redirected)

## Memory Management

### Resource Cleanup
Always clean up in `deinit`:
```swift
deinit {
    // Stop timers
    checkTimer?.invalidate()

    // Remove observers
    NSWorkspace.shared.notificationCenter.removeObserver(self)

    // Disable event taps
    if let eventTap = eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: false)
    }
}
```

**Pattern**: Explicitly invalidate timers, remove observers, disable event taps

### Strong References
- **Delegates**: Usually `weak` to avoid retain cycles
- **Closures**: Capture `[weak self]` when needed
- **Timers**: Hold strong reference, invalidate in `deinit`

## Concurrency

### DispatchQueue (Legacy GCD)
```swift
DispatchQueue.global(qos: .userInitiated).async {
    let thumbnail = captureThumbnail()
    DispatchQueue.main.async {
        self.updateUI(with: thumbnail)
    }
}
```

**Pattern**:
- Background work on `.global()` queue
- UI updates on `.main` queue
- Explicit QoS: `.userInitiated`, `.background`

### Async/Await (Modern)
```swift
Task {
    do {
        let image = try await SCScreenshotManager.captureImage(...)
        await MainActor.run {
            updateThumbnail(image)
        }
    } catch {
        NSLog("Capture failed: \(error)")
    }
}
```

**Pattern**: Used only for ScreenCaptureKit (requires async)

## Delegate Pattern

### Protocol Definition
```swift
protocol HotkeyDelegate: AnyObject {
    func hotkeyPressed()
    func hotkeyReleased()
}
```

**Conventions**:
- Protocol names end with `Delegate`
- Inherit from `AnyObject` (class-only, enables `weak`)
- Method names describe events: `hotkeyPressed()`, not `onHotkeyPress()`

### Delegate Usage
```swift
class HotkeyManager {
    weak var delegate: HotkeyDelegate?

    private func handleEvent() {
        delegate?.hotkeyPressed()
    }
}
```

**Pattern**: `weak var delegate` to avoid retain cycles

## C/Objective-C Bridging

### Unmanaged Pointers
For C callbacks needing context:
```swift
let context = Unmanaged.passUnretained(self).toOpaque()
CGEventTapCreate(..., context, callbackFunction)

// In callback:
let manager = Unmanaged<HotkeyManager>.fromOpaque(context).takeUnretainedValue()
```

**Pattern**: `passUnretained` / `takeUnretainedValue` (no ownership transfer)

### C Function Pointers
```swift
@convention(c)
func hotkeyEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    context: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // Bridge back to Swift
}
```

**Pattern**: Top-level function with `@convention(c)` attribute

### Private SPI
```swift
@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError
```

**Pattern**: `@_silgen_name` for undocumented C functions

## UI Conventions

### AppKit Idioms
- `NSPanel` for floating windows (not `NSWindow`)
- `NSStatusBar.system.statusItem()` for menu bar icon
- `NSMenu` + `NSMenuItem` for menu construction
- `NSImage(named:)` for asset catalog images

### View Hierarchy
```swift
panel.contentView?.addSubview(thumbnailView)
```

**Pattern**: Optional chaining for view hierarchy (safety)

### Auto Layout
Minimal use (mostly frame-based layout):
```swift
thumbnailView.frame = NSRect(x: x, y: y, width: w, height: h)
```

**Pattern**: Direct frame manipulation (simpler for dynamic layouts)

## Documentation

### Inline Comments
- Minimal comments (code should be self-explanatory)
- Comments explain *why*, not *what*:
  ```swift
  // TCC caches permission by code signature, ad-hoc signing breaks this
  let hasPermission = checkPermissionOptimistically()
  ```

### No DocC/Jazzy
- No structured documentation comments
- No `/// ...` doc comments
- No parameter/return value documentation

## Anti-Patterns (Avoided)

❌ **Force unwrapping**: Rarely used (only when guaranteed safe)
❌ **Implicitly unwrapped optionals**: Not used (`var foo: String!`)
❌ **Global state**: Avoided (dependency injection via delegates)
❌ **Singletons**: Only for system APIs (`NSWorkspace.shared`, etc.)
❌ **Storyboards/XIBs**: Pure programmatic UI
❌ **KVO**: Not used (use delegates instead)
❌ **NotificationCenter**: Only for system notifications, not custom events
