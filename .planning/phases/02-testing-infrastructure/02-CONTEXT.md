# Phase 2: Testing Infrastructure - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish comprehensive test coverage (60-80%) with mocked system APIs to enable confident refactoring. Build XCTest target, create mock implementations for all protocol abstractions, write unit tests for ViewModels and Services, and add integration tests for observer lifecycle and MRU tracking.

</domain>

<decisions>
## Implementation Decisions

### Test Target Configuration
- **D-01:** Separate AltTabTests target with dedicated test scheme
- **D-02:** Test bundle name: AltTabTests.xctest
- **D-03:** Executable via `make test` (Makefile already has xcodebuild test wired)
- **D-04:** Separate scheme allows running tests independently from main app build

### Mock Strategy
- **D-05:** Manual mock classes for all 6 protocols (AccessibilityProviding, WindowEnumerating, ThumbnailCaching, ThumbnailCapturing, MRUTracking, WindowTrackingService)
- **D-06:** Store mocks in AltTabTests/Mocks/ directory
- **D-07:** Each mock class conforms to its protocol with explicit, controllable behavior
- **D-08:** Mocks support both returning canned data (stub) and recording calls (spy) when needed

### Test Organization
- **D-09:** Organize by architectural layer:
  - AltTabTests/ViewModels/ — ViewModel unit tests
  - AltTabTests/Services/ — Service unit tests (MRU, enumeration, capture)
  - AltTabTests/Integration/ — Cross-layer integration tests
  - AltTabTests/Mocks/ — All mock implementations
- **D-10:** Test file naming: `<ClassName>Tests.swift` (e.g., SwitcherViewModelTests.swift)
- **D-11:** Test method naming: `testMethodName_condition()` (e.g., `testCycleNext_incrementsIndex()`)

### Coverage Strategy
- **D-12:** Priority order: Critical path first
  1. Window enumeration logic (filtering, layer checks, bounds validation)
  2. MRU tracking logic (promote, prune, ordering)
  3. SwitcherViewModel state management
  4. Supporting services (thumbnail cache, activation)
  5. Integration tests (observer callbacks, workspace notifications)
- **D-13:** Exclude from coverage calculation: Views (SwitcherPanel, ThumbnailView), AppDelegate bootstrap code, main.swift
- **D-14:** Target 60-80% overall coverage minimum
- **D-15:** Aim for 100% coverage on business logic (filtering, sorting, MRU)

### Integration Test Scope
- **D-16:** Integration tests verify:
  - AXObserver callbacks correctly update MRU order
  - NSWorkspace notifications trigger window re-enumeration
  - Observer lifecycle (install on startTracking, remove on stopTracking)
  - End-to-end flow: enumerate → filter → sort → present
- **D-17:** Use mocked system APIs (don't call real CGWindowList or AXUIElement in tests)
- **D-18:** Focus on service interactions and data flow, not UI rendering

### Security Checks
- **D-19:** Defer security checks to Phase 3 (Quality Assurance) and Phase 5 (Build & CI/CD)
- **D-20:** Phase 2 focus is test infrastructure only

### Claude's Discretion
- Exact assertion helpers and test utilities implementation
- Test data fixtures structure (how to create WindowInfo test instances)
- XCTest setup/teardown patterns
- Async test handling for thumbnail capture completion

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Testing — TEST-01 through TEST-10 define success criteria

### Architecture
- `AltTab/AltTab/Protocols.swift` — All 6 protocols that need mocking

### Existing Code
- `AltTab/AltTab/SwitcherViewModel.swift` — Primary ViewModel to test
- `AltTab/AltTab/MRUTracker.swift` — Critical path: MRU logic
- `AltTab/AltTab/WindowEnumerationService.swift` — Critical path: enumeration/filtering

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Protocols.swift**: All system API abstractions already defined (AccessibilityProviding, WindowEnumerating, ThumbnailCaching, ThumbnailCapturing, MRUTracking, WindowTrackingService)
- **SwitcherViewModel**: Clean ViewModel with protocol-typed dependencies, ready for dependency injection in tests
- **Makefile**: Has `make test` target pre-wired to `xcodebuild test` command

### Established Patterns
- Constructor-based dependency injection throughout (AppDelegate composes services, ViewModels receive protocols)
- Protocol abstractions isolate system APIs (CGWindowList, AXUIElement, NSCache, ScreenCaptureKit)
- Closure-based callbacks for async operations (thumbnailCapture completion, onUpdate)

### Integration Points
- Test target must reference main app target to access source files
- Mocks will conform to existing protocols (no changes to protocol definitions)
- Tests inject mocks via ViewModel/Service constructors
- XCTest target runs via xcodebuild in Makefile `test` target

### Testing Considerations
- **WindowInfo struct**: Need test fixtures for creating WindowInfo instances
- **Async completion handlers**: SwitcherViewModel.activate() has async thumbnail capture — need XCTestExpectation patterns
- **MRU seeding**: MRUTracker seeds from CGWindowList on init — mock or bypass in tests
- **Protocol count**: 6 protocols → 6 mock classes minimum

</code_context>

<specifics>
## Specific Ideas

- Test naming should be descriptive but concise: `testCycleNext_incrementsIndex()` not `test_whenCycleNextCalled_thenSelectedIndexIncrements()`
- Critical path first means window enumeration bugs (68% filtering issue) and MRU bugs get covered first
- Keep mocks simple initially — add spy behavior (call recording) only when needed for specific test assertions

</specifics>

<deferred>
## Deferred Ideas

### Phase 3 (Quality Assurance)
- SwiftLint security rules (force unwrap detection, weak crypto)
- Static Application Security Testing (SAST) via Semgrep or CodeQL

### Phase 5 (Build & CI/CD)
- GitHub Actions workflow running tests automatically
- Dependabot for dependency scanning (currently zero dependencies)
- Code coverage reporting in CI (failing build if coverage < 60%)

</deferred>

---

*Phase: 02-testing-infrastructure*
*Context gathered: 2026-04-07*
