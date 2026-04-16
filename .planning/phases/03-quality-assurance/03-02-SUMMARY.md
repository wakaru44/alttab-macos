---
phase: 03-quality-assurance
plan: 02
subsystem: core-services
tags: [bugfix, thread-safety, performance, window-enumeration, hotkey]
dependency_graph:
  requires: [03-01]
  provides: [fixed-window-filtering, no-polling-timer, thread-safe-hotkey]
  affects: [WindowEnumerationService, SettingsWindow, HotkeyManager]
tech_stack:
  added: []
  patterns: [serial-dispatch-queue, pid-based-filtering, on-demand-permission-check]
key_files:
  created:
    - AltTab/AltTabTests/WindowEnumerationServiceTests.swift
  modified:
    - AltTab/AltTab/WindowEnumerationService.swift
    - AltTab/AltTab/SettingsWindow.swift
    - AltTab/AltTab/HotkeyManager.swift
decisions:
  - PID-only self-filtering instead of string matching for robustness
  - On-demand refresh button instead of polling timer for permission status
  - Serial DispatchQueue for all hotkey state transitions
metrics:
  duration: 278s
  completed: "2026-04-16T13:41:40Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
  files_created: 1
---

# Phase 03 Plan 02: P1/P2 Bug Fixes Summary

Fixed three major bugs: window filtering debug logging, permission polling elimination, and hotkey state machine thread safety.

## One-liner

PID-only self-filter with debug logging, polling timer removed in favor of refresh button, serial queue for hotkey state

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Fix window filtering and permission polling bugs | 753e377 | Debug logging for filtered windows, PID-only self-filter, removed polling timer, added Refresh button |
| 2 | Add hotkey thread safety and regression tests | 9656a57 | serialQueue wrapping all state transitions, WindowEnumerationServiceTests added |

## Key Changes

### Window Filtering (WindowEnumerationService.swift)
- Split monolithic guard into separate guards with NSLog debug logging for layer and bounds filtering
- Self-filter now uses PID comparison only (`$0.ownerPID == selfPID`), removing fragile `"AltTab"` string match
- `selfPID` promoted to stored property to avoid repeated `ProcessInfo` calls

### Permission Polling (SettingsWindow.swift)
- Removed `permissionStatusTimer` property and `Timer.scheduledTimer` call (eliminated 60% CPU polling)
- Removed `deinit` that only invalidated the timer
- Added "Refresh Status" button for on-demand permission re-check
- Permission status still checked on `setupUI()` and `showWindow(_:)`

### Hotkey Thread Safety (HotkeyManager.swift)
- Added `private let serialQueue = DispatchQueue(label: "com.alttab.hotkey-state")`
- Wrapped all state reads/writes in `serialQueue.sync` (5 sync points):
  - `handleEvent` tap-disabled recovery
  - `handleFlagsChanged` option-release detection
  - `handleKeyDown` full state machine
  - `startReEnablePolling` force-cancel path

### Regression Tests (WindowEnumerationServiceTests.swift)
- `testSelfWindowsFilteredByPID` — verifies own-process windows excluded
- `testSelfFilterDoesNotUseStringMatching` — source-level regression guard
- `testEnumerateWindowsReturnsArray` — smoke test

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `make test`: TEST SUCCEEDED (all existing + new tests pass)
- `swiftlint lint --strict HotkeyManager.swift`: 0 violations
- `Timer.scheduledTimer` count in SettingsWindow.swift: 0
- `serialQueue` count in HotkeyManager.swift: 5
- `permissionStatusTimer` count in SettingsWindow.swift: 0
- `ownerName == "AltTab"` count in WindowEnumerationService.swift: 0

## Self-Check: PASSED
