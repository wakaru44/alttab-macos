# Codebase Structure

**Analysis Date:** 2026-04-06

## Directory Layout

```
app.alttab-macos/
├── AltTab/                          # Xcode project container
│   ├── AltTab/                      # Main source code directory
│   │   ├── main.swift               # App entry point
│   │   ├── AppDelegate.swift        # Lifecycle and orchestration
│   │   ├── HotkeyManager.swift      # Global hotkey detection
│   │   ├── WindowModel.swift        # Window enumeration and MRU
│   │   ├── WindowCapture.swift      # ScreenCaptureKit thumbnail capture
│   │   ├── SwitcherPanel.swift      # Switcher overlay UI (NSPanel)
│   │   ├── ThumbnailView.swift      # Individual window cell (NSView)
│   │   ├── WindowActivator.swift    # Window switching logic
│   │   ├── PermissionManager.swift  # Permission checks and polling
│   │   ├── PreferencesMenu.swift    # Status bar menu
│   │   ├── SettingsWindow.swift     # Settings window controller
│   │   └── Assets.xcassets/         # App icons and images
│   ├── AltTab.xcodeproj/            # Xcode project configuration
│   │   ├── project.pbxproj          # Build settings and file references
│   │   ├── project.xcworkspace/     # Workspace state
│   │   └── xcshareddata/            # Shared build settings
│   └── build/                       # Build artifacts (generated)
├── build.sh                         # Build and install script
├── Makefile                         # Development targets
├── README.md                        # Documentation
├── CHANGELOG.md                     # Version history
├── Lessons learnt.md                # Developer notes
├── LICENSE                          # MIT License
└── Screenshots/                     # Marketing images
```

## Directory Purposes

**AltTab/AltTab/**
- Purpose: All Swift source code for the application
- Contains: 11 Swift files, one asset catalog
- Key files: `main.swift`, `AppDelegate.swift`
- Build artifact: Compiled binary included in AltTab.app bundle

**AltTab/AltTab.xcodeproj/**
- Purpose: Xcode project configuration and metadata
- Contains: Build settings, file references, schemes, build phases
- Key files: `project.pbxproj` (master project file)
- Not edited directly: Use Xcode IDE or scripted xcodebuild

**AltTab/build/**
- Purpose: Generated build artifacts and caches
- Contains: Compiled object files, intermediate build products, index cache
- Generated: Yes
- Committed: No (in .gitignore)

## Key File Locations

**Entry Points:**
- `AltTab/AltTab/main.swift`: Programmatic app initialization (creates NSApplication and AppDelegate)
- `AltTab/AltTab/AppDelegate.swift`: Lifecycle entry point (applicationDidFinishLaunching)

**Core Logic:**
- `AltTab/AltTab/HotkeyManager.swift`: Global hotkey detection and state machine (3-state: idle/active/idle)
- `AltTab/AltTab/WindowModel.swift`: Window enumeration, MRU tracking, AXObserver management
- `AltTab/AltTab/WindowActivator.swift`: Switching logic (unminimize, activate app, raise window)
- `AltTab/AltTab/WindowCapture.swift`: ScreenCaptureKit thumbnail capture with caching

**UI Layer:**
- `AltTab/AltTab/SwitcherPanel.swift`: Floating NSPanel overlay with backdrop and scroll view
- `AltTab/AltTab/ThumbnailView.swift`: Individual window cell with thumbnail/icon, title, app name

**Utilities:**
- `AltTab/AltTab/PermissionManager.swift`: Accessibility and Screen Recording permission checks
- `AltTab/AltTab/PreferencesMenu.swift`: Status bar dropdown menu (Settings, Launch at Login, Quit)
- `AltTab/AltTab/SettingsWindow.swift`: Settings window with permission status and controls

**Configuration:**
- `AltTab/AltTab.xcodeproj/project.pbxproj`: Build settings, deployment target, code signing
- `build.sh`: Installation and build orchestration
- `Makefile`: Development targets (build, run, clean)

## Naming Conventions

**Files:**
- Pattern: `[Subsystem][Responsibility].swift` (examples: HotkeyManager, WindowModel, SwitcherPanel)
- Each file contains one primary class/struct/enum
- File names match class names exactly (Swift convention)

**Classes/Structs:**
- Pattern: PascalCase (examples: AppDelegate, HotkeyManager, WindowInfo, ThumbnailView)
- Protocols: PascalCase with "Delegate" suffix if callback-oriented (example: HotkeyDelegate)
- Enums: PascalCase (examples: WindowActivator, State)
- Structs: PascalCase (examples: WindowInfo)

**Functions:**
- Pattern: camelCase (examples: hotkeyDidActivate, enumerateWindows, captureThumbnails)
- Private functions: prefix with underscore or use `private` modifier (example: `private func installEventTap()`)
- Delegate callbacks: verb + "Did" + action (examples: hotkeyDidActivate, hotkeyDidCycleNext)

**Variables:**
- Pattern: camelCase (examples: currentWindows, selectedIndex, mruOrder, eventTap)
- Constants: camelCase or UPPER_SNAKE_CASE (examples: maxTapRetries, Self.baseTapRetryInterval)
- Private instance variables: prefix with underscore in some contexts (example: `_screenRecordingCached`)

**Types/Generics:**
- Pattern: PascalCase (examples: CGWindowID, NSRunningApplication, AXUIElement)
- Type aliases: camelCase with context (examples: none used currently)

## Where to Add New Code

**New Feature (e.g., keyboard shortcut customization):**
- Primary code: `AltTab/AltTab/[FeatureName].swift` (create new file)
- If extends HotkeyManager behavior: add method to `HotkeyManager.swift` and HotkeyDelegate protocol
- If modifies window switching: extend `WindowActivator.swift` or `WindowModel.swift`
- Settings UI: add to `SettingsWindow.swift`

**New Component/Module:**
- Implementation: Create new file in `AltTab/AltTab/` named `[ComponentName].swift`
- Protocol definition: In same file or dedicated protocol file if shared
- Registration: Initialize in `AppDelegate.applicationDidFinishLaunching()`
- Coordination: Wire via AppDelegate or existing delegate protocols

**Utilities:**
- Shared helpers: Add to existing utility file (`PermissionManager.swift`, `WindowActivator.swift`)
- Cross-module extensions: Add extension file (e.g., `Notification+Names.swift`)
- Current pattern: Extensions on Notification.Name for custom notification types (see line 166 in SwitcherPanel.swift, line 71 in PermissionManager.swift)

**UI Elements:**
- New views: Create `[ElementName]View.swift` inheriting from NSView (follow ThumbnailView pattern)
- Window controllers: Create `[ElementName]Window.swift` inheriting from NSWindowController (follow SettingsWindow pattern)
- Panels: Inherit from NSPanel (follow SwitcherPanel pattern)
- All UI must manage layout via NSLayoutConstraint or autoresizingMask

**Tests:**
- Not yet implemented (no test files present)
- Suggested location: `AltTab/AltTabTests/` directory
- Suggested naming: `[Module]Tests.swift` (examples: HotkeyManagerTests, WindowModelTests)

## Special Directories

**AltTab/AltTab/Assets.xcassets/**
- Purpose: App icon and asset catalog (managed by Xcode)
- Contains: Icon set for various sizes, launch screen assets
- Generated: Partially (compiled by Xcode)
- Committed: Yes (source .imageset files committed)

**AltTab/build/**
- Purpose: Generated build artifacts
- Generated: Yes (created by xcodebuild)
- Committed: No (.gitignore entry)
- To clean: Run `./build.sh clean` or `rm -rf AltTab/build`

**AltTab/AltTab.xcodeproj/xcshareddata/**
- Purpose: Shared Xcode build settings and schemes
- Generated: No (hand-edited)
- Committed: Yes (part of version control)

## Code Organization

**Subsystem Isolation:**
- Each subsystem (Hotkey, Window, UI, Permissions) in separate files
- Minimal cross-imports between subsystems
- All subsystems initialized and coordinated by AppDelegate
- Delegate protocols used for loose coupling (HotkeyDelegate)

**Dependency Direction:**
- Input layer (HotkeyManager) → Model layer (WindowModel, WindowActivator) → UI layer (SwitcherPanel)
- AppDelegate at center orchestrating all directions
- Utilities (PermissionManager, WindowActivator) have no dependencies on UI or hotkey

**Layering Pattern:**
```
AppDelegate (orchestration) ↔ HotkeyManager (input)
       ↓                           ↓
     Model ← ← ← ← ← ← ← ← ← ← ← ↓
  (WindowModel, WindowCapture, WindowActivator)
       ↓
      UI
  (SwitcherPanel, ThumbnailView)
```

## Build Configuration

**Development:**
- Target: AltTab (macOS app)
- Configuration: Debug (when running via build.sh run)
- Minimum OS: macOS 14.0 (Sonoma)
- Architecture: arm64 (Apple Silicon) + x86_64 (Intel)

**Production:**
- Configuration: Release
- Code signing: Required (developer certificate)
- Entitlements: Accessibility, Screen Recording permissions

**Build Command:**
```bash
./build.sh build              # Builds Release configuration
./build.sh run                # Builds and runs from build directory
./build.sh install            # Builds and installs to ~/Applications
```

---

*Structure analysis: 2026-04-06*
