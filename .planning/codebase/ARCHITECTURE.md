# Architecture

**Analysis Date:** 2026-04-06

## Pattern Overview

**Overall:** Event-driven menu bar utility with delegate-based coordination and layered separation of concerns (input → model → UI).

**Key Characteristics:**
- Single-purpose menu bar app (no Dock icon, accessory activation policy)
- Global hotkey interception via CGEvent tap at session level
- Three-state machine (idle → active → idle) for Option-Tab detection
- Asynchronous thumbnail capture with caching and graceful degradation
- Accessibility API for window enumeration and control
- Non-activating floating panel UI that doesn't steal focus

## Layers

**Input/Hotkey Detection:**
- Purpose: Capture global keyboard events and emit application state changes
- Location: `AltTab/AltTab/HotkeyManager.swift`
- Contains: CGEvent tap, state machine (idle/active), retry logic with exponential backoff
- Depends on: Cocoa, Carbon.HIToolbox, delegate callbacks
- Used by: AppDelegate via HotkeyDelegate protocol

**Window Model:**
- Purpose: Enumerate open windows, maintain MRU order, track focus changes
- Location: `AltTab/AltTab/WindowModel.swift`
- Contains: Window discovery (CGWindowListCopyWindowInfo + AXUIElement), MRU ordering, AXObserver management, workspace notifications
- Depends on: ApplicationServices, NSWorkspace, private _AXUIElementGetWindow SPI
- Used by: AppDelegate for enumerateWindows(), promoteToFront()

**Window Capture:**
- Purpose: Asynchronously capture window thumbnails with caching and graceful fallback
- Location: `AltTab/AltTab/WindowCapture.swift`
- Contains: ScreenCaptureKit integration, thumbnail caching, background async capture
- Depends on: ScreenCaptureKit (macOS 14.0+)
- Used by: AppDelegate after hotkey activation

**Window Activation:**
- Purpose: Switch to a selected window (unminimize, activate app, raise window)
- Location: `AltTab/AltTab/WindowActivator.swift`
- Contains: Static functions for unminimize, window raising, fallback matching strategies
- Depends on: NSRunningApplication, AXUIElement, private _AXUIElementGetWindow SPI
- Used by: AppDelegate on hotkey confirm

**UI Layer:**
- Purpose: Display and manage the switcher overlay and thumbnail cells
- Location: `AltTab/AltTab/SwitcherPanel.swift`, `AltTab/AltTab/ThumbnailView.swift`
- Contains: NSPanel with NSVisualEffectView backdrop, NSStackView of cells, selection state, click handling
- Depends on: Cocoa, AppKit
- Used by: AppDelegate for show(), updateSelection(), dismiss()

**Permissions:**
- Purpose: Check and request Accessibility and Screen Recording permissions
- Location: `AltTab/AltTab/PermissionManager.swift`, `AltTab/AltTab/SettingsWindow.swift`
- Contains: Permission checks, polling timers, system settings navigation
- Depends on: ApplicationServices, ServiceManagement, ScreenCaptureKit
- Used by: AppDelegate (PermissionManager) and status bar menu (SettingsWindow)

**Application Orchestration:**
- Purpose: Lifecycle management, coordinate all subsystems
- Location: `AltTab/AltTab/AppDelegate.swift`
- Contains: Status bar item, notification center observers, hotkey/window/UI coordination
- Depends on: All other modules
- Used by: Entry point (NSApplication delegate)

## Data Flow

**Hotkey Activation (Option+Tab):**

1. Global CGEvent tap intercepts Option+Tab keypress
2. HotkeyManager state machine transitions to `.active`
3. HotkeyManager calls `AppDelegate.hotkeyDidActivate()`
4. AppDelegate:
   - Calls `WindowModel.enumerateWindows()` → gets MRU-sorted list
   - Calls `SwitcherPanel.show()` → displays switcher with app icons immediately
   - Calls `WindowCapture.captureThumbnails()` asynchronously in background
   - Updates switcher panel with thumbnails when ready (if still active)

**Hotkey Cycling (Tab/Arrow Keys):**

1. CGEvent tap captures Tab/Arrow key in active state
2. HotkeyManager calls `AppDelegate.hotkeyDidCycleNext()` or `hotkeyDidCyclePrevious()`
3. AppDelegate updates `selectedIndex` and calls `SwitcherPanel.updateSelection()`
4. SwitcherPanel updates visual selection and scrolls to show selected cell

**Hotkey Confirm (Option Release / Enter):**

1. Option key release triggers flagsChanged event
2. HotkeyManager state machine transitions to `.idle`
3. HotkeyManager calls `AppDelegate.hotkeyDidConfirm()`
4. AppDelegate:
   - Gets selected window from `currentWindows[selectedIndex]`
   - Calls `WindowActivator.activate(window:)`
   - Calls `WindowModel.promoteToFront(windowID:)` for MRU update
   - Dismisses switcher panel

**MRU Ordering:**

- Seeded at startup from CGWindowList stacking order
- Updated on app activation via NSWorkspace notification
- Updated on intra-app window focus change via AXObserver callbacks
- Filtered/pruned to valid window IDs on each enumeration

**State Management:**

- `AppDelegate.currentWindows`: Live window list during active switcher
- `AppDelegate.selectedIndex`: Currently highlighted window (0 to count-1)
- `AppDelegate.switcherActive`: Boolean flag (true while switcher is visible)
- `WindowModel.mruOrder`: Array of CGWindowID in most-recently-used order
- `HotkeyManager.state`: Enum state (idle/active) for Option hold/release tracking

## Key Abstractions

**WindowInfo:**
- Purpose: Immutable value type representing a single window
- Location: `AltTab/AltTab/WindowModel.swift` (struct definition)
- Pattern: Value type with computed property for app icon
- Properties: windowID, ownerPID, ownerName, windowTitle, bounds, isMinimized, optional thumbnail

**HotkeyDelegate:**
- Purpose: Protocol for hotkey state machine events
- Location: `AltTab/AltTab/HotkeyManager.swift`
- Pattern: Weak delegate for decoupled input handling
- Methods: hotkeyDidActivate(), hotkeyDidCycleNext(), hotkeyDidCyclePrevious(), hotkeyDidConfirm(), hotkeyDidCancel()

**WindowActivator (Enum):**
- Purpose: Namespace for static window switching functions
- Location: `AltTab/AltTab/WindowActivator.swift`
- Pattern: Utility enum with no instance state
- Methods: activate(window:), and private helpers for unminimize/raise with fallback strategies

**ThumbnailView (NSView subclass):**
- Purpose: Individual window cell in switcher strip
- Location: `AltTab/AltTab/ThumbnailView.swift`
- Pattern: Self-contained view with layout constraints, selection state, and mouse handling
- State: isSelected property (didSet triggers updateAppearance), onClicked closure

**SwitcherPanel (NSPanel subclass):**
- Purpose: The overlay window displaying window thumbnails
- Location: `AltTab/AltTab/SwitcherPanel.swift`
- Pattern: Custom NSPanel with non-activating style mask and floating behavior
- Style: NSVisualEffectView backdrop with hudWindow material, horizontal NSStackView of ThumbnailViews

## Entry Points

**main.swift:**
- Location: `AltTab/AltTab/main.swift`
- Triggers: App launch (implicit by macOS runtime)
- Responsibilities: Creates NSApplication instance, instantiates AppDelegate, runs event loop

**AppDelegate.applicationDidFinishLaunching():**
- Location: `AltTab/AltTab/AppDelegate.swift` (lines 33-71)
- Triggers: Called by NSApplication after launch
- Responsibilities:
  - Sets accessory activation policy (no Dock icon)
  - Creates and installs status bar item
  - Initializes all subsystems: PermissionManager, WindowModel, WindowCapture, SwitcherPanel, HotkeyManager
  - Checks accessibility permission with retry logic
  - Registers notification observers for permission changes

**HotkeyManager.handleEvent():**
- Location: `AltTab/AltTab/HotkeyManager.swift` (lines 158-181)
- Triggers: Global CGEvent tap callback (bridged via C function pointer)
- Responsibilities:
  - Routes events to handleFlagsChanged() or handleKeyDown()
  - Implements state machine transitions
  - Delegates to HotkeyDelegate protocol

## Error Handling

**Strategy:** Permissive fallback approach. App continues with degraded functionality rather than crashing.

**Patterns:**

- **Permission Denial:** If Accessibility is denied, event tap fails to create. HotkeyManager retries with exponential backoff up to 10 attempts, then logs and gives up. If permission is granted later, a polling timer re-attempts creation.

- **Window Enumeration Failure:** If CGWindowListCopyWindowInfo or AXUIElement queries fail, empty arrays are handled safely. No crash, just empty switcher list.

- **Thumbnail Capture Failure:** ScreenCaptureKit failures are caught and logged. UI falls back to app icons without interrupting. Cached thumbnails prevent re-attempts if cache hit.

- **Window Not Found:** WindowActivator uses three fallback strategies: match by CGWindowID (primary), fallback to title matching, last resort use first window of app.

- **AXUIElement Errors:** Accessibility API calls return AXError. All calls check return codes before dereferencing results. Failed calls are logged but don't interrupt flow.

## Cross-Cutting Concerns

**Logging:** Standard NSLog used throughout. File locations: `AppDelegate.swift` (main app flow), `HotkeyManager.swift` (event tap state), `WindowModel.swift` (enumeration/MRU), `WindowCapture.swift` (capture progress), `SettingsWindow.swift` (permission UI). No log file rotation or filtering.

**Validation:**
- Window geometry validated (width > 0, height > 0)
- Window layer checked (must be 0 for user windows)
- PID and window ID sanity-checked before use
- Empty titles and app names handled with fallbacks

**Authentication:** Accessibility and Screen Recording permissions checked via macOS system APIs. No custom auth. Required at startup; optional runtime prompting available via settings window.

**Thread Safety:**
- Main thread: AppDelegate, SwitcherPanel, ThumbnailView, UIThread work via DispatchQueue.main
- Background threads: HotkeyManager event tap (system-managed), WindowCapture async tasks (global dispatch queue)
- All delegate callbacks and UI updates dispatch to main queue explicitly

---

*Architecture analysis: 2026-04-06*
