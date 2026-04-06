# Technology Stack

## Languages & Runtime

**Primary Language**: Swift 5.9+
- Modern Swift with async/await support
- Xcode 15+ as primary IDE
- No Objective-C files (pure Swift except C bridging)

**Platform Target**: macOS 14.0+ (Sonoma/Sequoia)
- Raised from 13.0 due to ScreenCaptureKit requirements
- x86_64 and arm64 (Universal Binary)

## Core Frameworks

### AppKit & Foundation
- **AppKit**: Main UI framework for macOS native apps
- **NSApplication**: App lifecycle and event handling
- **NSWindow**: Custom window management for switcher panel
- **NSPanel**: Floating panel UI for app switcher
- **NSMenu**: Menu bar interface (`PreferencesMenu.swift`)
- **NSStatusBar**: System menu bar integration
- **NSImage**: Image handling for icons and thumbnails
- **NSCache**: In-memory thumbnail caching

### System Frameworks

**ApplicationServices**
- `CGEvent` / `CGEventTap`: Global keyboard event monitoring
  - Hotkey detection (Cmd+Tab equivalent)
  - Event tap for system-wide keyboard capture
- `AXUIElement`: Accessibility API for window control
  - `_AXUIElementGetWindow` (private SPI) - maps AX elements to CGWindowID
  - Window activation and manipulation
- `CGWindowList`: Window enumeration
  - `CGWindowListCopyWindowInfo` - get all windows
  - Layer filtering, bounds checking

**ScreenCaptureKit** (macOS 14.0+)
- `SCScreenshotManager`: Window thumbnail capture
  - Replaced deprecated `CGWindowListCreateImage` (obsolete in macOS 15)
  - Requires Screen Recording permission
  - `captureImage(contentFilter:configuration:)` for window screenshots

**ServiceManagement**
- `SMAppService`: Launch at Login support
  - Modern replacement for deprecated `SMLoginItemSetEnabled`
  - User preference for autostart

**Carbon.HIToolbox**
- Legacy keyboard APIs for hotkey registration
- Virtual key code constants

## Build System

**Xcode Project**: `AltTab.xcodeproj`
- Standard Xcode build configuration
- No external build systems (no Carthage, CocoaPods, SPM dependencies)

**Custom Build Scripts**:
- `build.sh`: Command-line build automation
- `Makefile`: Build orchestration
  - Targets: `build`, `clean`, `run`, `install`

**Code Signing**:
- Ad-hoc signing for development (causes TCC permission issues)
- Production requires Apple Developer certificate for stable TCC identity

## Dependencies

**Zero External Dependencies**
- No package manager (no SPM, CocoaPods, Carthage)
- No third-party frameworks
- Pure macOS native frameworks only
- Intentionally lightweight (~11 Swift files)

## Configuration Files

**Project Configuration**:
- `Info.plist`: Bundle metadata, LSUIElement (agent app, no dock icon)
- `AltTab.entitlements`: Required entitlements
  - `com.apple.security.personal-information.screen-capture` (ScreenCaptureKit)
- `Assets.xcassets`: App icon and image assets

**No external config files**: No YAML/JSON/TOML configuration

## Permissions & Entitlements

**Required Permissions**:
1. **Accessibility** (mandatory)
   - Window enumeration via AXUIElement
   - Window activation
   - System-wide event monitoring

2. **Screen Recording** (optional, for thumbnails)
   - ScreenCaptureKit thumbnail capture
   - Gracefully degrades to app icon fallback

**TCC (Transparency, Consent, and Control)**:
- Permissions managed by macOS TCC system
- Ad-hoc signing causes permission cache issues
- Production builds need stable code signature

## Development Tools

**Logging**:
- `NSLog()` for development debugging (writes to stderr)
- Logs redirected to `/tmp/alttab-debug.log`
- Avoided `os.log` (doesn't write to stderr, invisible in custom log files)

**Debugging**:
- Xcode debugger (lldb)
- Console.app for system logs
- TCC reset commands for permission debugging

## Architecture Notes

**App Type**: LSUIElement (background agent app)
- No dock icon
- No main menu bar
- Menu bar status item only
- Runs invisibly until hotkey pressed

**Memory Management**:
- ARC (Automatic Reference Counting)
- Manual cleanup in `deinit` for system resources (timers, observers, event taps)

**Concurrency**:
- `DispatchQueue` for background work (legacy GCD)
- `Task` for async/await (ScreenCaptureKit)
- Main thread for UI updates

## Private APIs (Risks)

**_AXUIElementGetWindow** (undocumented SPI)
- Used throughout codebase for AX → CGWindow mapping
- Not part of official Accessibility API
- Could break in future macOS versions
- Alternative: Bundle `SkyLight.framework` private symbols (also risky)
