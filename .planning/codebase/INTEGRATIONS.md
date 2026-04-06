# External Integrations

## System APIs

### CGEvent & Event Taps
**Purpose**: Global keyboard monitoring for hotkey detection

**Location**: `HotkeyManager.swift`

**API Usage**:
- `CGEvent.tapCreate()`: Create system-wide event tap
- `CGEventTapEnable()`: Enable/disable event monitoring
- Event mask: `.keyDown`, `.keyUp`, `.flagsChanged`
- Callback: `hotkeyEventCallback` (C function pointer via `@convention(c)`)

**Permissions Required**: Accessibility access

**Data Flow**:
1. User presses Cmd+Tab (or configured hotkey)
2. Event tap intercepts keypress before other apps
3. Callback invokes Swift delegate method
4. Switcher panel shows/hides based on event

### Accessibility API (AXUIElement)
**Purpose**: Window enumeration, activation, and control

**Location**: `WindowModel.swift`, `WindowActivator.swift`

**API Usage**:
- `AXUIElementCreateApplication()`: Get app's AX element
- `AXUIElementCopyAttributeValue()`: Query window properties
- `AXUIElementSetAttributeValue()`: Activate windows
- **Private SPI**: `_AXUIElementGetWindow()` - undocumented API
  - Maps AXUIElement → CGWindowID (required for thumbnails)
  - Risk: Could break in future macOS versions

**Permissions Required**: Accessibility access (mandatory)

**Data Exchanged**:
- Window titles, bounds, minimized state
- App names, bundle IDs, process IDs
- Focus state, layer information

### CGWindowList
**Purpose**: System-wide window enumeration

**Location**: `WindowModel.swift`

**API Usage**:
- `CGWindowListCopyWindowInfo()`: Get list of all windows
  - Options: `.optionOnScreenOnly`, `.excludeDesktopElements`
  - Returns array of window dictionaries with metadata
- `CGWindowID`: Window identifiers for thumbnail capture

**Filters Applied**:
- `kCGWindowLayer == 0` (normal windows only)
- `width > 0 && height > 0` (valid bounds)
- Known issue: Filters too aggressive, hides 17 of 25 windows

**Data Returned**:
- Window ID, owner PID, bounds, layer, on-screen state
- Window name, owner name, sharing state

### ScreenCaptureKit
**Purpose**: Window thumbnail capture (replaced deprecated CGWindowListCreateImage)

**Location**: `WindowCapture.swift`

**API Usage**:
- `SCShareableContent.current`: Enumerate capturable windows
  - **WARNING**: Extremely expensive call (60% CPU on WindowServer)
  - Should only be called when actually capturing, not for permission checks
- `SCContentFilter(desktopIndependentWindow:)`: Filter for specific window
- `SCScreenshotManager.captureImage()`: Capture window screenshot
  - Async API (uses Swift Task/await)

**Permissions Required**: Screen Recording access (optional)
- Gracefully degrades to app icon if denied
- Permission check itself is unreliable (false negatives)

**Entitlements**:
```xml
<key>com.apple.security.personal-information.screen-capture</key>
<true/>
```

**Known Issues**:
- macOS 15 (Sequoia): Old API (`CGWindowListCreateImage`) returns `nil` silently
- TCC permission cache issues with ad-hoc signing
- Permission polling causes high CPU usage

### NSWorkspace Notifications
**Purpose**: App lifecycle and window change detection

**Location**: `WindowModel.swift`, `AppDelegate.swift`

**Notifications Observed**:
- `NSWorkspace.didLaunchApplicationNotification`
- `NSWorkspace.didTerminateApplicationNotification`
- `NSWorkspace.didActivateApplicationNotification`
- `NSWorkspace.activeSpaceDidChangeNotification`

**Data Flow**:
1. System posts workspace notification
2. App observes notification
3. Window list refreshes
4. UI updates to reflect changes

### AXObserver Callbacks
**Purpose**: Real-time window state changes

**Location**: `WindowModel.swift`

**API Usage**:
- `AXObserverCreate()`: Create observer for specific app
- `AXObserverAddNotification()`: Subscribe to window events
  - `kAXWindowCreatedNotification`
  - `kAXUIElementDestroyedNotification`
  - `kAXFocusedWindowChangedNotification`
  - `kAXWindowMiniaturizedNotification`

**Callback**: C function bridge (`@convention(c)`) with Unmanaged pointer

**Data Synchronization**: Updates window list in real-time

## System Services

### Launch Services
**Purpose**: App metadata and launch coordination

**Location**: `ServiceManagement` integration

**API Usage**:
- `SMAppService.mainApp.register()`: Register for Login Items
- `NSWorkspace.shared.runningApplications`: Enumerate running apps

### TCC (Transparency, Consent, and Control)
**Purpose**: Privacy permission management

**Location**: `PermissionManager.swift`, `SettingsWindow.swift`

**TCC Database Interaction**:
- System prompts user for Accessibility/Screen Recording access
- Permissions cached by code signature
- Ad-hoc signing = unstable identity = TCC confusion

**Known Issues**:
- Ad-hoc builds create new signature each rebuild
- TCC caches stale permission denials
- `tccutil reset` doesn't work for apps not in database
- Workaround: Manual addition via System Settings

**Permission Check Strategy**:
- **Accessibility**: `AXIsProcessTrusted()` (reliable)
- **Screen Recording**: Optimistic check (avoid expensive `SCShareableContent.current`)

## Data Storage

**In-Memory Only**:
- `NSCache<NSNumber, NSImage>`: Thumbnail cache (LRU eviction)
- No persistent storage (no CoreData, SQLite, plist)
- No network requests
- No cloud sync

**Cache Strategy**:
1. First invocation: Capture thumbnails asynchronously
2. Store in NSCache keyed by CGWindowID
3. Subsequent invocations: Apply cached thumbnails synchronously before showing UI
4. Background refresh for cache misses

## No External Services

**Zero Network Communication**:
- No analytics/telemetry
- No crash reporting services (Sentry, Crashlytics)
- No update checking
- No API calls

**Fully Offline**: App operates entirely locally with system APIs

## IPC (Inter-Process Communication)

**Mechanisms Used**:
1. **CGEvent Tap**: Global keyboard events
2. **AXObserver**: Per-app window change notifications
3. **NSWorkspace**: System-wide app/workspace notifications
4. **ScreenCaptureKit**: WindowServer screenshot requests

**No Custom IPC**:
- No XPC services
- No distributed notifications
- No Mach ports
- No Unix sockets

## Security Considerations

**Attack Surface**:
1. **Private API Dependency**: `_AXUIElementGetWindow` could be removed
2. **Event Tap Vulnerability**: Intercepts all keyboard input (requires Accessibility)
3. **Screen Recording Permission**: Can capture arbitrary window contents

**Mitigations**:
- LSUIElement (no dock presence, less visible)
- Minimal permissions requested
- No network access (can't exfiltrate data)
- Open source (auditable)

**Privacy**:
- No data leaves the device
- Thumbnails cached in memory only (cleared on quit)
- No logging of user activity (beyond debugging)
