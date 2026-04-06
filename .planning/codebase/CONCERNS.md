# Technical Concerns & Debt

## Critical Issues

### 1. Zero Test Coverage 🔴
**Risk**: High | **Effort**: High | **Priority**: P0

**Problem**: No automated tests exist. All changes validated manually.

**Impact**:
- No regression protection
- Refactoring is risky
- Known bugs could resurface silently
- No CI/CD test automation

**Affected Files**: All (no test files exist)

**Remediation**:
1. Add XCTest target to `AltTab.xcodeproj`
2. Unit test hotkey state machine (`HotkeyManager.swift`)
3. Unit test window filtering (`WindowModel.swift`)
4. Mock Accessibility API via protocol abstraction
5. Add test automation to Makefile/CI

**References**: See `.planning/codebase/TESTING.md`

---

### 2. TCC Permission Hell 🔴
**Risk**: High | **Effort**: Medium | **Priority**: P1

**Problem**: Ad-hoc signing creates unstable code signature, confusing TCC.

**Symptoms**:
- Permission appears "denied" when user was never asked
- Each rebuild = new signature = TCC cache invalidation
- `tccutil reset` doesn't work (app not in database)
- False negatives on permission checks

**Affected Files**:
- `PermissionManager.swift` - Permission checking logic
- `SettingsWindow.swift` - Permission UI
- `WindowCapture.swift` - Screen Recording permission usage

**Workarounds Currently Used**:
1. Manual addition to System Settings (not scalable for users)
2. Kill `tccd` daemon to reload permissions (requires sudo)
3. Clear `~/Library/Application Support/com.apple.TCC/AdhocSignatureCache/`

**Production Solution**:
- Sign with stable Apple Developer certificate (not ad-hoc)
- Developer ID signing maintains stable identity across builds
- TCC correctly remembers permissions

**References**:
- Documented in `Lessons learnt.md` (lines 13-43)
- [Apple Developer Forums - TCC](https://developer.apple.com/forums/thread/730043)

---

### 3. Expensive Permission Polling 🔴
**Risk**: High | **Effort**: Low | **Priority**: P1

**Problem**: `SCShareableContent.current` called repeatedly to check Screen Recording permission, causing 60% CPU usage on WindowServer.

**Location**: `SettingsWindow.swift` (permission status polling)

**Details**:
- Timer checks permission every 2-5 seconds
- `SCShareableContent.current` is extremely expensive (not meant for polling)
- Causes high CPU on WindowServer process
- Check itself is unreliable (false negatives)

**Current Mitigation**:
- Slowed timer from 2s → 5s (helps but doesn't solve)

**Better Solution**:
- Don't call `SCShareableContent.current` for checks
- Optimistically assume permission granted if app in System Settings
- Only call when actually capturing (one-time cost)
- Use TCC database query if available (less expensive)

**Code Location**:
```swift
// SettingsWindow.swift
checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    // Expensive call here - should be removed
    Task { await checkScreenRecordingPermission() }
}
```

**Remediation**:
1. Remove polling timer
2. Check permission only on user action (toggle switch)
3. Cache result optimistically
4. Provide manual "Refresh" button if needed

**References**: `Lessons learnt.md` (lines 97-107)

---

### 4. Window Enumeration Filtering Issues 🟡
**Risk**: Medium | **Effort**: Medium | **Priority**: P2

**Problem**: Overly aggressive filters hide valid windows. `CGWindowListCopyWindowInfo` returns 25 windows, but only 8 pass filters.

**Location**: `WindowModel.swift` - `parseWindowInfo()` method

**Current Filters**:
```swift
// Likely too strict:
guard layer == 0 else { return nil }  // Normal window layer
guard width > 0 && height > 0 else { return nil }  // Valid bounds
guard onScreen else { return nil }  // Currently visible
```

**Known Issues**:
- 17 of 25 windows filtered out (68% rejection rate)
- Current window sometimes missing from list
- Minimized windows included but shouldn't be prioritized
- Some valid background windows hidden

**Investigation Needed**:
1. Log filtered windows to understand what's being rejected
2. Check if layer filter is too strict (some valid windows on other layers?)
3. Review bounds filter (zero-size windows might be valid?)
4. MRU ordering puts minimized windows first (wrong priority)

**Affected User Experience**:
- Missing windows in switcher
- Wrong window shown as "current"
- Inconsistent window list

**Remediation**:
1. Add debug logging for filtered windows
2. Relax filters incrementally
3. Add unit tests for filter logic
4. Fix MRU ordering (prioritize visible over minimized)

**References**: `Lessons learnt.md` (lines 89-96)

---

### 5. Private API Dependency 🟡
**Risk**: Medium | **Effort**: High | **Priority**: P3

**Problem**: Core functionality depends on undocumented `_AXUIElementGetWindow` SPI.

**Location**: `WindowModel.swift`, `WindowCapture.swift`

**Usage**:
```swift
@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(
    _ element: AXUIElement,
    _ windowID: UnsafeMutablePointer<CGWindowID>
) -> AXError

// Used throughout to map AX elements → CGWindowID for thumbnails
```

**Risk**:
- Not part of official Accessibility API
- Could be removed in future macOS versions
- No backward compatibility guarantees from Apple
- App Store rejection possible (though unlikely for public distribution)

**Why It's Needed**:
- Maps `AXUIElement` (from Accessibility) → `CGWindowID` (for ScreenCaptureKit)
- No official API provides this mapping
- Required to capture thumbnails for specific windows

**Alternatives**:
1. Bundle `SkyLight.framework` private symbols (also risky)
2. Heuristic matching (compare window bounds/titles - unreliable)
3. Abandon thumbnails (degrade to icons only - bad UX)

**Mitigation**:
- Document dependency clearly
- Have fallback to icon-only mode if API fails
- Monitor macOS betas for API removal
- Consider contributing to Feedback Assistant for official API

**References**: Private SPI used in window enumeration flow

---

### 6. Incomplete Click-to-Select Feature 🟡
**Risk**: Low | **Effort**: Medium | **Priority**: P3

**Problem**: User can't click on thumbnails to select windows (keyboard-only navigation).

**Location**: `SwitcherPanel.swift`, `ThumbnailView.swift`

**Current State**:
- Keyboard navigation works (arrow keys, Tab)
- Mouse hover shows highlight (visual feedback exists)
- Click doesn't activate selection

**Expected Behavior**:
- Click thumbnail → activate that window
- Double-click → activate and close switcher

**Missing Implementation**:
- `mouseDown(with:)` event handler in `ThumbnailView`
- Delegate callback to notify `SwitcherPanel` of selection

**User Impact**:
- Keyboard-only interaction (accessibility issue)
- Inconsistent with macOS Cmd+Tab behavior (which allows clicking)

**Remediation**:
```swift
// ThumbnailView.swift
override func mouseDown(with event: NSEvent) {
    delegate?.thumbnailClicked(self)
    super.mouseDown(with: event)
}
```

---

### 7. Fragile Hotkey State Machine 🟡
**Risk**: Medium | **Effort**: Low | **Priority**: P2

**Problem**: 3-state hotkey logic (`idle` → `capturing` → `releasing`) has no tests and uses unsafe C callback bridge.

**Location**: `HotkeyManager.swift`

**State Machine**:
```
idle → (hotkey down) → capturing → (hotkey up) → releasing → idle
```

**Fragile Areas**:
1. **C Callback Bridge**:
   ```swift
   @convention(c)
   func hotkeyEventCallback(..., context: UnsafeMutableRawPointer?) {
       let manager = Unmanaged<HotkeyManager>.fromOpaque(context!).takeUnretainedValue()
       // Force unwrap + manual memory management
   }
   ```

2. **Race Conditions**:
   - Event tap runs on background thread
   - Delegate calls cross thread boundaries
   - No explicit synchronization

3. **State Leaks**:
   - If event tap disabled mid-sequence, state stuck in `capturing`
   - No timeout to reset state

**Known Bugs**: None observed, but high risk for future changes

**Remediation**:
1. Add unit tests for state transitions
2. Add explicit synchronization (serial DispatchQueue)
3. Add state timeout/reset mechanism
4. Consider safer callback bridge (wrap in class method)

---

## Technical Debt

### 8. No Documentation 🟢
**Risk**: Low | **Effort**: Medium | **Priority**: P4

**Problem**: No inline documentation, no README, no architecture docs (except this planning folder).

**Missing**:
- README.md with setup instructions
- Architecture overview (now in `.planning/codebase/ARCHITECTURE.md`)
- Inline doc comments (`///` for public APIs)
- Deployment guide
- Contribution guidelines

**Remediation**:
- Add README with project description, build instructions, permissions guide
- Document public APIs (at minimum)
- Keep `.planning/codebase/` docs updated

---

### 9. Hard-Coded Configuration 🟢
**Risk**: Low | **Effort**: Low | **Priority**: P4

**Problem**: No user-configurable settings (hotkey, thumbnail size, etc.).

**Examples**:
- Hotkey: Hard-coded to Cmd+Tab (no customization)
- Thumbnail size: Hard-coded to 200x150
- Panel position: Center screen only
- Window filters: Not user-adjustable

**User Requests**:
- Custom hotkey combinations
- Thumbnail size slider
- Panel position preferences
- Include/exclude specific apps

**Remediation**:
- Add `UserDefaults` for preferences
- Extend Settings window with configuration UI
- Persist user choices across launches

---

### 10. No Crash Reporting 🟢
**Risk**: Low | **Effort**: Medium | **Priority**: P4

**Problem**: No telemetry or crash reporting. Users can't easily report issues.

**Current State**:
- Crashes are silent (user just sees app quit)
- No stack traces sent to developers
- Debugging requires user to reproduce locally

**Options**:
1. Integrate Sentry/Crashlytics (adds network dependency)
2. Write crash logs to known location (e.g., `~/Library/Logs/AltTab/`)
3. Built-in bug report UI (collect logs + system info)

**Privacy Concern**: Any telemetry must be opt-in and transparent

**Remediation**:
- Add local crash log collection (no network)
- Settings checkbox: "Send crash reports" (opt-in)
- Include system info in bug reports (macOS version, permissions granted)

---

## Security Considerations

### 11. Event Tap Attack Surface 🟡
**Risk**: Medium | **Effort**: None (inherent) | **Priority**: Monitor

**Problem**: App intercepts all keyboard input when active (Accessibility permission).

**Attack Scenario**:
- Malicious code in app could log keystrokes
- No runtime sandboxing (LSUIElement app)
- Full access to keyboard events

**Mitigations**:
1. Open source (auditable)
2. No network access (can't exfiltrate data)
3. Minimal permissions requested
4. Explicit user consent required (TCC prompt)

**Best Practice**:
- Don't store/log keyboard events
- Minimize event tap duration (only while switcher active)
- Clear documentation of privacy stance

---

### 12. ScreenCaptureKit Data Exposure 🟡
**Risk**: Medium | **Effort**: None (inherent) | **Priority**: Monitor

**Problem**: Can capture screenshots of any window (Screen Recording permission).

**Attack Scenario**:
- Capture sensitive windows (password managers, bank apps)
- Thumbnails cached in memory (could be swapped to disk)
- No encryption of cached thumbnails

**Mitigations**:
1. No persistence (cache cleared on quit)
2. No network access (can't exfiltrate)
3. User-granted Screen Recording permission required
4. Graceful degradation (icons if permission denied)

**Best Practice**:
- Don't persist thumbnails to disk
- Clear cache aggressively
- Respect user permission revocation

---

## Performance Issues

### 13. Thumbnail Capture Latency 🟢
**Risk**: Low | **Effort**: Medium | **Priority**: P4

**Problem**: First invocation shows icons, then thumbnails "pop in" after delay.

**Current State**:
- Cache miss: 100-200ms per window thumbnail
- Async capture happens after switcher shown
- User sees flash from icons → thumbnails

**Mitigation Already Implemented**:
- Synchronous cache hit check before showing UI
- Second+ invocations instant (cached)

**Remaining Issue**:
- First invocation still slow (no pre-warming)

**Potential Improvements**:
1. Pre-warm cache on app launch (background thread)
2. Capture thumbnails proactively on window changes
3. Prioritize visible windows (lazy-load offscreen)

**Trade-offs**:
- Pre-warming uses CPU/memory
- Proactive capture may hit permission issues
- Complexity increase for marginal UX gain

---

## Dependency Risks

### 14. macOS Version Compatibility 🟡
**Risk**: Medium | **Effort**: Low | **Priority**: Monitor

**Current Target**: macOS 14.0+ (Sonoma/Sequoia)

**Breaking Changes Already Hit**:
- macOS 15: `CGWindowListCreateImage` returns `nil` (deprecated)
- Required migration to ScreenCaptureKit

**Future Risks**:
- macOS 16+: Private API `_AXUIElementGetWindow` could be removed
- Accessibility API changes (deprecations, permission model changes)
- TCC policy changes

**Mitigation**:
- Test on macOS betas early
- Have fallback for private API removal
- Monitor deprecation warnings in Xcode

---

## Code Quality

### 15. Mixed Concurrency Models 🟢
**Risk**: Low | **Effort**: High | **Priority**: P4

**Problem**: Codebase mixes legacy GCD (`DispatchQueue`) with modern async/await.

**Examples**:
- `WindowCapture.swift`: Uses `Task` + `async/await` (ScreenCaptureKit)
- `WindowModel.swift`: Uses `DispatchQueue.global().async` (legacy)
- `HotkeyManager.swift`: C callbacks + GCD

**Inconsistency**:
- Hard to reason about execution context
- Mixing patterns increases cognitive load
- Potential for threading bugs

**Ideal State**:
- Migrate fully to async/await (requires macOS 14.0+, already met)
- Use `@MainActor` for UI updates
- Structured concurrency throughout

**Effort**: High (requires refactoring most async code)

**Priority**: Low (functional, just not modern)

---

## Summary

| Priority | Issue | Risk | Effort |
|----------|-------|------|--------|
| **P0** | Zero test coverage | 🔴 High | High |
| **P1** | TCC permission hell | 🔴 High | Medium |
| **P1** | Expensive permission polling | 🔴 High | Low |
| **P2** | Window filtering issues | 🟡 Medium | Medium |
| **P2** | Fragile hotkey state machine | 🟡 Medium | Low |
| **P3** | Private API dependency | 🟡 Medium | High |
| **P3** | Click-to-select missing | 🟡 Low | Medium |
| **P4** | Hard-coded config | 🟢 Low | Low |
| **P4** | No documentation | 🟢 Low | Medium |
| **P4** | Mixed concurrency | 🟢 Low | High |

**Total Critical Issues**: 3 (test coverage, TCC, polling)
**Total Warnings**: 5 (filtering, state machine, private API, click, security)
**Total Debt**: 5 (config, docs, crash reporting, latency, concurrency)

---

## Recommendations

### Immediate Actions (Next Sprint)
1. Fix expensive permission polling (`SettingsWindow.swift`)
2. Add XCTest target to project
3. Unit test hotkey state machine
4. Sign with Developer ID (solve TCC issues)

### Short-Term (Next Month)
1. Investigate window filtering (add logging, fix MRU)
2. Implement click-to-select
3. Add unit tests for window filtering
4. Write README.md

### Long-Term (Next Quarter)
1. Migrate fully to async/await
2. Add crash reporting
3. User-configurable settings (hotkey, thumbnail size)
4. Monitor private API in macOS betas

**Focus**: Stabilize core functionality (tests, permissions) before adding features.
