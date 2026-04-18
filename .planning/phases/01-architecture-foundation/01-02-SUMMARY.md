---
phase: 01-architecture-foundation
plan: 02
subsystem: architecture
tags: [swift, appkit, mru-tracking, window-tracking, axobserver, nsworkspace, accessibility]

# Dependency graph
requires:
  - phase: 01-architecture-foundation
    plan: 01
    provides: "Protocol abstractions (MRUTracking, WindowTrackingService, AccessibilityProviding)"
provides:
  - "MRUTracker service for MRU window ordering state management"
  - "WindowTracker service for real-time window focus and app lifecycle tracking"
  - "Complete AXObserver lifecycle management (install per-app, observe focus changes)"
  - "NSWorkspace notification handling for app activation/launch/termination"
affects: [01-03, 01-04, testing]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Observer pattern for window focus tracking", "Service lifecycle management (start/stop)", "C callback bridging to Swift class instance"]

key-files:
  created:
    - AltTab/AltTab/MRUTracker.swift
    - AltTab/AltTab/WindowTracker.swift
  modified:
    - AltTab/AltTab.xcodeproj/project.pbxproj

key-decisions:
  - "MRUTracker seeds from CGWindowList stacking order on initialization"
  - "WindowTracker uses constructor DI for AccessibilityProviding and MRUTracking"
  - "AXObserver C callback bridges to WindowTracker instance method (Unmanaged pattern)"
  - "Explicit startTracking/stopTracking lifecycle enables testing and cleanup"

patterns-established:
  - "Service initialization: seed state from system (MRUTracker seeds from window list)"
  - "Observer lifecycle: install on app launch, remove on app terminate"
  - "Callback bridging: C callback → Unmanaged<T>.fromOpaque() → Swift instance method"

requirements-completed: [ARCH-06, TRACK-01, TRACK-02, TRACK-03, TRACK-04, TRACK-05, TRACK-06, TRACK-07, TRACK-08, TRACK-09, TRACK-10]

# Metrics
duration: 8min
completed: 2026-04-06
---

# Phase 01 Plan 02: MRU Tracking and Window Observation Services Summary

**MRUTracker and WindowTracker services extract MRU ordering and real-time window/app tracking from WindowModel god object using protocol-based DI**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-06T22:24:35Z
- **Completed:** 2026-04-06T22:32:58Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- Created MRUTracker service with promoteToFront, orderedIDs, and prune methods
- MRUTracker seeds MRU order from CGWindowList stacking order on initialization
- Created WindowTracker service with full AXObserver and NSWorkspace notification lifecycle
- WindowTracker installs AXObserver per running app for kAXFocusedWindowChangedNotification
- WindowTracker observes NSWorkspace notifications for app activation, launch, and termination
- Explicit startTracking/stopTracking lifecycle for proper resource management
- C callback bridges to WindowTracker Swift instance using Unmanaged pattern
- Uses protocol dependencies (AccessibilityProviding, MRUTracking) instead of concrete types
- All 10 TRACK requirements covered (TRACK-01 through TRACK-10)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create MRUTracker service** - `b520f5d` (feat)
2. **Task 2: Create WindowTracker with AXObserver and NSWorkspace tracking** - `46ebbae` (feat)

## Files Created/Modified

**Created:**
- `AltTab/AltTab/MRUTracker.swift` - MRU ordering state management conforming to MRUTracking protocol
- `AltTab/AltTab/WindowTracker.swift` - Real-time window focus and app lifecycle tracking conforming to WindowTrackingService

**Modified:**
- `AltTab/AltTab.xcodeproj/project.pbxproj` - Added both new files to Xcode project build

## Decisions Made

**1. MRUTracker seeds from CGWindowList stacking order**
- Rationale: Provides sensible initial MRU order matching actual window Z-order at app launch
- Implementation: Uses CGWindowListCopyWindowInfo with .optionOnScreenOnly filter

**2. WindowTracker uses constructor-based dependency injection**
- Rationale: Enables testing with mocked AccessibilityService and MRUTracker
- Implementation: `init(accessibilityService: AccessibilityProviding, mruTracker: MRUTracking)`

**3. AXObserver C callback bridges to Swift instance**
- Rationale: AXObserver API requires C function pointer, need to route to Swift object method
- Implementation: Pass `Unmanaged.passUnretained(self).toOpaque()` as userInfo, retrieve with `Unmanaged<WindowTracker>.fromOpaque(userInfo).takeUnretainedValue()`

**4. Explicit lifecycle methods (startTracking/stopTracking)**
- Rationale: Enables explicit resource management, testability, and prevents observer leaks
- Implementation: startTracking installs observers, stopTracking removes all and clears NSWorkspace notifications

## Deviations from Plan

**Auto-fixed Issues:**

**1. [Rule 3 - Blocking] Added Plan 01-01 files to Xcode project**
- **Found during:** Task 2 build verification
- **Issue:** MRUTracking protocol not found - Protocols.swift and other 01-01 files existed but weren't in project.pbxproj
- **Fix:** Added Protocols.swift, AccessibilityService.swift, WindowEnumerationService.swift, and ThumbnailRepository.swift to project
- **Files modified:** AltTab/AltTab.xcodeproj/project.pbxproj
- **Commit:** 46ebbae (combined with Task 2)
- **Rationale:** Parallel execution worktree - Plan 01-01 files present but not in project, blocking compilation

## Issues Encountered

**Xcode project.pbxproj manipulation challenges:**
- Initial Python script approach corrupted project file (invalid syntax in buildPhases/buildRules/dependencies arrays)
- Multiple restore attempts required to recover clean state
- Final approach: Python script with careful regex-based insertions at correct positions
- Lesson: pbxproj format is fragile, safer to use xcodeproj gem or minimal surgical edits

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Plan 01-03:**
- MRUTracker ready for integration into WindowModel replacement
- WindowTracker ready for integration into application lifecycle
- Both services tested via successful compilation
- All TRACK requirements addressed (window focus observation, app lifecycle tracking, MRU promotion)

**Ready for Plan 01-04:**
- Services demonstrate constructor DI pattern for ViewModels to follow
- Protocol-based dependencies enable test doubles

**Blockers/Concerns:**
- None - both services compile successfully and conform to protocols

## Self-Check: PASSED

All created files verified to exist:
- AltTab/AltTab/MRUTracker.swift
- AltTab/AltTab/WindowTracker.swift

All commits verified:
- b520f5d (Task 1)
- 46ebbae (Task 2)

---
*Phase: 01-architecture-foundation*
*Completed: 2026-04-06*
