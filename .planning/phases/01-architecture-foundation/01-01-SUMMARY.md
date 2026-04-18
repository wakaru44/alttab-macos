---
phase: 01-architecture-foundation
plan: 01
subsystem: architecture
tags: [swift, appkit, protocols, dependency-injection, accessibility, cgwindowlist, axuielement]

# Dependency graph
requires:
  - phase: none
    provides: "Initial codebase with god object WindowModel"
provides:
  - "Protocol abstractions for all system APIs (AccessibilityProviding, WindowEnumerating, ThumbnailCaching, ThumbnailCapturing, MRUTracking, WindowTrackingService)"
  - "AccessibilityService wrapping AXUIElement calls"
  - "WindowEnumerationService with constructor-based dependency injection"
  - "ThumbnailRepository wrapping NSCache"
affects: [01-02, 01-03, 01-04, testing, quality-assurance]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Protocol-based system API abstractions", "Constructor-based dependency injection", "Repository pattern for caching"]

key-files:
  created:
    - AltTab/AltTab/Protocols.swift
    - AltTab/AltTab/AccessibilityService.swift
    - AltTab/AltTab/WindowEnumerationService.swift
    - AltTab/AltTab/ThumbnailRepository.swift
  modified: []

key-decisions:
  - "Protocol abstractions enable testability and clean separation from system APIs"
  - "Constructor injection used instead of DI framework (appropriate for app size)"
  - "Repository pattern abstracts NSCache for future flexibility"
  - "Private SPI _AXUIElementGetWindow remains in WindowModel.swift (will be moved in later task)"

patterns-established:
  - "Protocol-first design: Define protocol before implementation"
  - "AnyObject protocol constraint: Enables weak references for delegates"
  - "Single Responsibility: Each protocol has focused, cohesive methods"
  - "Interface Segregation: No protocol has more than 8 methods"

requirements-completed: [ARCH-02, ARCH-07, ARCH-08, ARCH-09]

# Metrics
duration: 1min
completed: 2026-04-06
---

# Phase 01 Plan 01: Protocol Abstractions and Service Foundation Summary

**Protocol-based system API abstractions with AccessibilityService, WindowEnumerationService, and ThumbnailRepository using constructor dependency injection**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-06T22:20:16Z
- **Completed:** 2026-04-06T22:21:15Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created 6 protocol definitions for complete system API abstraction layer
- Implemented AccessibilityService wrapping all AXUIElement operations with 8 focused methods
- Implemented WindowEnumerationService using constructor DI for AccessibilityProviding and MRUTracking dependencies
- Implemented ThumbnailRepository as clean abstraction over NSCache

## Task Commits

Each task was committed atomically:

1. **Task 1: Create protocol definitions and AccessibilityService** - `4743491` (feat)
2. **Task 2: Create WindowEnumerationService and ThumbnailRepository** - `8e47b11` (feat)

## Files Created/Modified

**Created:**
- `AltTab/AltTab/Protocols.swift` - All 6 protocol definitions (AccessibilityProviding, WindowEnumerating, ThumbnailCaching, ThumbnailCapturing, MRUTracking, WindowTrackingService)
- `AltTab/AltTab/AccessibilityService.swift` - Wraps AXUIElement calls: axWindows, focusedWindow, windowID, windowTitle, isMinimized, setMinimized, raiseWindow, setMainWindow
- `AltTab/AltTab/WindowEnumerationService.swift` - Enumerates windows using CGWindowList (on-screen) and AXUIElement (minimized), sorts by MRU
- `AltTab/AltTab/ThumbnailRepository.swift` - NSCache wrapper conforming to ThumbnailCaching protocol

**Modified:**
- None (clean creation of new abstraction layer)

## Decisions Made

**1. Protocol-first approach for all system APIs**
- Rationale: Enables testability via mocking, allows swapping implementations, enforces clean boundaries

**2. Constructor-based dependency injection**
- Rationale: Lightweight approach appropriate for 11-file app, no DI framework overhead needed

**3. Repository pattern for thumbnail caching**
- Rationale: Abstracts NSCache implementation details, enables future persistence changes or multi-tier caching

**4. Private SPI _AXUIElementGetWindow remains in WindowModel.swift**
- Rationale: Will be moved/refactored in later tasks, acceptable technical debt for now

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - straightforward protocol extraction and service implementation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Plan 01-02:**
- Protocol abstractions complete and compiled successfully
- AccessibilityService ready to be injected into WindowEnumerationService
- WindowEnumerationService ready for MRUTracker integration (01-02)
- ThumbnailRepository ready for use in WindowCapture refactoring (01-03)

**Blockers/Concerns:**
- None - all protocols defined, foundation layer solid

## Self-Check: PASSED

All created files verified to exist:
- AltTab/AltTab/Protocols.swift
- AltTab/AltTab/AccessibilityService.swift
- AltTab/AltTab/WindowEnumerationService.swift
- AltTab/AltTab/ThumbnailRepository.swift

All commits verified:
- 4743491 (Task 1)
- 8e47b11 (Task 2)

---
*Phase: 01-architecture-foundation*
*Completed: 2026-04-06*
