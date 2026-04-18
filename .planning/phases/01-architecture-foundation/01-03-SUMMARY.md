---
phase: 01-architecture-foundation
plan: 03
subsystem: architecture
tags: [swift, appkit, mvvm, viewmodel, dependency-injection, protocols]

# Dependency graph
requires:
  - phase: 01-architecture-foundation
    plan: 01
    provides: "Protocol abstractions (ThumbnailCapturing, AccessibilityProviding)"
  - phase: 01-architecture-foundation
    plan: 02
    provides: "MRUTracker service"
provides:
  - "SwitcherViewModel as MVVM mediation layer between views and services"
  - "WindowCapture refactored to use ThumbnailCaching protocol DI"
  - "WindowActivator refactored to use AccessibilityProviding protocol DI"
  - "Complete protocol-based dependency injection for all core services"
affects: [01-04, testing, ui-layer]

# Tech tracking
tech-stack:
  added: []
  patterns: ["MVVM architecture", "ViewModel mediation layer", "Declarative view binding via closures"]

key-files:
  created:
    - AltTab/AltTab/SwitcherViewModel.swift
  modified:
    - AltTab/AltTab/WindowCapture.swift
    - AltTab/AltTab/WindowActivator.swift
    - AltTab/AltTab/AccessibilityService.swift
    - AltTab/AltTab.xcodeproj/project.pbxproj

key-decisions:
  - "SwitcherViewModel uses onUpdate closure for declarative view binding"
  - "All ViewModel dependencies are protocol-typed (enables testing)"
  - "WindowActivator converted from static enum to instance class with DI"
  - "WindowCapture uses injected ThumbnailCaching instead of direct NSCache"

patterns-established:
  - "MVVM mediation: ViewModel coordinates between multiple services"
  - "Declarative view updates: onUpdate closure instead of delegates"
  - "Protocol-first DI: All dependencies injected as protocols"
  - "State encapsulation: private(set) for read-only external access"

requirements-completed: [ARCH-01, ARCH-03, ARCH-04, ARCH-05, ARCH-10, ARCH-11]

# Metrics
duration: 3min
completed: 2026-04-06
---

# Phase 01 Plan 03: ViewModel Layer and Service DI Completion Summary

**SwitcherViewModel mediates between views and services with protocol-based DI, WindowCapture and WindowActivator refactored to use injected dependencies**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-06T22:35:23Z
- **Completed:** 2026-04-06T22:38:53Z
- **Tasks:** 2
- **Files created:** 1
- **Files modified:** 4

## Accomplishments

- Refactored WindowCapture to conform to ThumbnailCapturing protocol with injected ThumbnailCaching dependency
- Refactored WindowActivator from static enum to instance class with injected AccessibilityProviding dependency
- Removed all direct system API calls from WindowCapture (NSCache) and WindowActivator (AXUIElement)
- Created SwitcherViewModel as MVVM mediation layer coordinating WindowEnumerating, ThumbnailCapturing, WindowActivator, and MRUTracking
- ViewModel exposes state as private(set) properties (windows, selectedIndex, isActive)
- ViewModel uses onUpdate closure for declarative view binding
- All dependencies protocol-typed for testability
- Complete MVVM architecture foundation established

## Task Commits

Each task was committed atomically:

1. **Task 1: Refactor WindowCapture and WindowActivator to use protocol DI** - `648ecdb` (feat)
2. **Task 2: Create SwitcherViewModel** - `22efd8b` (feat)

## Files Created/Modified

**Created:**
- `AltTab/AltTab/SwitcherViewModel.swift` - MVVM ViewModel coordinating all services with protocol dependencies

**Modified:**
- `AltTab/AltTab/WindowCapture.swift` - Now conforms to ThumbnailCapturing, uses injected ThumbnailCaching
- `AltTab/AltTab/WindowActivator.swift` - Converted from enum to class, uses injected AccessibilityProviding
- `AltTab/AltTab/AccessibilityService.swift` - Removed duplicate _AXUIElementGetWindow declaration
- `AltTab/AltTab.xcodeproj/project.pbxproj` - Added SwitcherViewModel.swift to build

## Decisions Made

**1. WindowActivator converted to instance class with DI**
- Rationale: Enables testing via mock AccessibilityProviding, follows protocol-based DI pattern
- Impact: Breaking change to call sites (AppDelegate), will be updated in plan 01-04

**2. SwitcherViewModel uses onUpdate closure for view binding**
- Rationale: Simpler than delegate pattern, declarative style, single callback sufficient for this use case
- Impact: Views bind to onUpdate and refresh whenever ViewModel state changes

**3. All ViewModel dependencies protocol-typed**
- Rationale: Enables mocking for unit tests, enforces interface segregation
- Impact: ViewModel is fully testable without real system APIs

**4. State exposed as private(set) properties**
- Rationale: Views can read but not mutate state, mutations only via ViewModel methods
- Impact: Clear separation of concerns, enforces unidirectional data flow

## Deviations from Plan

**Auto-fixed Issues:**

**1. [Rule 1 - Bug] Fixed duplicate _AXUIElementGetWindow declaration**
- **Found during:** Task 2 build verification
- **Issue:** Compilation failed due to duplicate @_silgen_name declaration in AccessibilityService.swift and WindowModel.swift
- **Fix:** Removed declaration from AccessibilityService.swift, kept in WindowModel.swift (original location)
- **Files modified:** AltTab/AltTab/AccessibilityService.swift
- **Commit:** 22efd8b (combined with Task 2)
- **Rationale:** Duplicate declaration breaks compilation, declaration already exists globally in WindowModel.swift

## Issues Encountered

**Expected compilation errors in AppDelegate.swift:**
- AppDelegate still uses old API: `WindowCapture()` without parameters, `WindowActivator.activate()` static call
- These are expected - AppDelegate refactoring is plan 01-04
- The new WindowCapture and WindowActivator code compiles correctly
- No errors in any files created/modified in this plan

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Plan 01-04:**
- SwitcherViewModel ready for integration into AppDelegate
- WindowCapture ready for instantiation with ThumbnailRepository injection
- WindowActivator ready for instantiation with AccessibilityService injection
- MVVM pattern established for view layer refactoring
- Complete protocol-based DI foundation in place

**Blockers/Concerns:**
- None - MVVM layer complete, all services use protocol DI

## Self-Check: PASSED

All created files verified to exist:
- AltTab/AltTab/SwitcherViewModel.swift

All modified files verified:
- AltTab/AltTab/WindowCapture.swift
- AltTab/AltTab/WindowActivator.swift
- AltTab/AltTab/AccessibilityService.swift

All commits verified:
- 648ecdb (Task 1)
- 22efd8b (Task 2)

---
*Phase: 01-architecture-foundation*
*Completed: 2026-04-06*

## Self-Check Verification

**Files created:**
✓ AltTab/AltTab/SwitcherViewModel.swift

**Commits:**
✓ 648ecdb (Task 1: Refactor WindowCapture and WindowActivator)
✓ 22efd8b (Task 2: Create SwitcherViewModel)

**Status:** PASSED
