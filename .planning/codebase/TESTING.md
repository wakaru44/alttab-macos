# Testing Strategy

## Current State: Zero Test Coverage

**Critical Finding**: This codebase has **no automated tests**.

### What's Missing
- ❌ No test files in the project
- ❌ No test framework configured (no XCTest, Quick, Nimble)
- ❌ No test targets in Xcode project
- ❌ No unit tests
- ❌ No integration tests
- ❌ No UI tests (XCUITest)
- ❌ No performance tests
- ❌ No snapshot tests
- ❌ No CI/CD test runs

### Project Structure
```
AltTab/
  AltTab/                 # Main app
    *.swift              # 11 source files
  AltTab.xcodeproj       # Xcode project (single target)
  build.sh               # Build script (no test invocation)
  Makefile              # No 'test' target
```

**No `AltTabTests/` directory exists.**

## Why This Is Problematic

### High-Risk Areas Without Tests

1. **Hotkey State Machine** (`HotkeyManager.swift`)
   - 3-state logic: idle → capturing → releasing
   - Event tap callback bridge (C ↔ Swift)
   - No tests for state transitions or race conditions

2. **Window Enumeration** (`WindowModel.swift`)
   - Complex filtering logic (17 of 25 windows filtered out)
   - AX observer callbacks with `Unmanaged` pointers
   - MRU (Most Recently Used) ordering bugs (minimized windows prioritized incorrectly)

3. **Permission Management** (`PermissionManager.swift`)
   - Unreliable permission checks (false negatives)
   - Expensive polling (`SCShareableContent.current` = 60% CPU)
   - TCC cache issues with ad-hoc signing

4. **Thumbnail Caching** (`WindowCapture.swift`)
   - Async capture → cache → UI update flow
   - Cache hit/miss logic (NSCache eviction)
   - ScreenCaptureKit async/await error handling

5. **C/Objective-C Bridging**
   - Event tap callbacks: `@convention(c)` + `Unmanaged` pointers
   - AX observer callbacks: Manual memory management
   - Private SPI: `_AXUIElementGetWindow` (undocumented, could break)

### Known Bugs (Untested)
From `Lessons learnt.md`:
- Window enumeration filters too aggressive
- Minimized windows take precedence in MRU ordering
- Current window sometimes missing from list
- TCC permission false negatives
- Screen Recording check causes high CPU usage

**None of these have regression tests.**

## Manual Testing Only

### Current Validation Approach
1. **Rebuild and run** in Xcode
2. **Press hotkey** (Cmd+Tab) to invoke switcher
3. **Visual inspection** of UI
4. **Check logs** in `/tmp/alttab-debug.log`
5. **Reset TCC** and rebuild to test permission flow

### Manual Test Checklist (Informal)
- [ ] Hotkey triggers switcher
- [ ] Thumbnails load (or degrade to icons)
- [ ] Switching between windows works
- [ ] Settings window opens
- [ ] Permissions show correct state
- [ ] App quits cleanly

**Problem**: No automation, no regression protection, no CI

## Testing Challenges

### macOS System Integration
Testing this app is inherently difficult:

1. **Accessibility API**: Requires system permissions
   - Can't easily mock `AXUIElement` interactions
   - Tests would need full Accessibility access

2. **ScreenCaptureKit**: Requires Screen Recording permission
   - `SCScreenshotManager` can't be mocked easily
   - Tests need real windows to capture

3. **CGEvent Taps**: Require Accessibility permission
   - Global event monitoring can't run in sandboxed tests
   - Simulating system-wide hotkeys is complex

4. **TCC Permissions**: Non-deterministic
   - Permission state varies by environment
   - Ad-hoc signing makes tests unreliable

5. **WindowServer Integration**: Can't be mocked
   - `CGWindowListCopyWindowInfo` returns real system state
   - Tests would see actual running apps

### Potential Testing Strategy (Not Implemented)

**Unit Tests** (Testable without permissions):
- ✅ Window filtering logic (pure functions)
- ✅ MRU ordering algorithm
- ✅ Cache key generation
- ✅ Hotkey state machine transitions (with mocked callbacks)

**Integration Tests** (Require real system):
- ⚠️ Accessibility API calls (requires permission)
- ⚠️ Window enumeration (sees real apps)
- ⚠️ Thumbnail capture (requires Screen Recording)

**UI Tests** (XCUITest):
- ⚠️ Switcher panel appearance
- ⚠️ Settings window interaction
- ⚠️ Keyboard navigation

**Mock Strategy**:
- Protocol-based dependency injection for testability
- Separate business logic from system API calls
- Stub ScreenCaptureKit/Accessibility responses

**CI Considerations**:
- GitHub Actions macOS runners have no UI session
- Can't grant Accessibility/Screen Recording in CI
- Would need headless test subset (unit tests only)

## Recommendations

### Immediate Priorities
1. **Add XCTest target** to Xcode project
2. **Unit test hotkey state machine** (highest risk, pure logic)
3. **Unit test window filtering** (known bugs here)
4. **Mock Accessibility API** via protocol abstraction
5. **Test thumbnail cache logic** (hit/miss/eviction)

### Test Infrastructure
```
AltTab/
  AltTab/              # Existing app code
  AltTabTests/         # NEW: Unit tests
    WindowModelTests.swift
    HotkeyManagerTests.swift
    WindowCaptureTests.swift
  AltTabUITests/       # NEW: UI tests (optional)
```

### Makefile Addition
```makefile
test:
	xcodebuild test -scheme AltTab -destination 'platform=macOS'
```

### CI/CD
- Run unit tests on every PR (GitHub Actions)
- Skip integration tests requiring permissions
- Manual QA for system permission flows

## Test Coverage Goals

**Phase 1** (Foundation):
- [ ] Hotkey state machine: 80%+ coverage
- [ ] Window filtering: 80%+ coverage
- [ ] MRU ordering: 100% coverage
- [ ] Cache logic: 80%+ coverage

**Phase 2** (Integration):
- [ ] Mock Accessibility API via protocols
- [ ] Test window enumeration (mocked)
- [ ] Test permission checks (mocked TCC responses)

**Phase 3** (UI):
- [ ] XCUITest for switcher panel
- [ ] Settings window interaction tests
- [ ] Keyboard navigation tests

## Current Reality

**Testing Status**: ❌ None
**Risk Level**: 🔴 High
**Regression Protection**: ❌ None
**CI/CD**: ❌ Not configured

**All changes validated manually. No safety net for refactoring.**
