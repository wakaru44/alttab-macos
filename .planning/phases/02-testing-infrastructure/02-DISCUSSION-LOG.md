# Phase 2: Testing Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-07
**Phase:** 02-testing-infrastructure
**Areas discussed:** Test target & mock strategy, Test organization & coverage, Security checks

---

## Test Target Configuration

| Option | Description | Selected |
|--------|-------------|----------|
| Separate AltTabTests scheme | Create AltTabTests target + scheme. Run via 'make test' or Xcode. Clean separation, standard practice. | ✓ |
| Shared AltTab scheme with tests | Add tests to main AltTab scheme. Simpler setup but tests always run on build. | |
| SPM-style Tests directory | Create Tests/ directory with Package.swift. Non-standard for Xcode app projects. | |

**User's choice:** Separate AltTabTests scheme (Recommended)
**Notes:** Clean separation between app and test targets. Makefile already has `make test` wired to xcodebuild.

---

## Mock Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Manual mock classes | Write MockWindowEnumerator, MockAccessibility, etc. Full control, easy to debug. Stored in AltTabTests/Mocks/. | ✓ |
| Protocol witness pattern | Use closures to implement protocol methods. More flexible but harder to debug. | |
| Spy/Stub hybrid approach | Mocks record calls + return canned data. Good for verifying interactions. More overhead. | |

**User's choice:** Manual mock classes (Recommended)
**Notes:** 6 protocols need mocking: AccessibilityProviding, WindowEnumerating, ThumbnailCaching, ThumbnailCapturing, MRUTracking, WindowTrackingService. Manual mocks provide explicit behavior and easier debugging.

---

## Test Organization

| Option | Description | Selected |
|--------|-------------|----------|
| By layer | AltTabTests/ViewModels/, AltTabTests/Services/, AltTabTests/Integration/, AltTabTests/Mocks/. Clear layer separation. | ✓ |
| Mirror source structure | AltTabTests/ mirrors AltTab/ exactly. Traditional approach. | |
| Flat with prefixes | All tests in root with prefixes (VM_SwitcherTests.swift). Simple but scales poorly. | |

**User's choice:** By layer (Recommended)
**Notes:** Architectural layers map directly to test organization. Easy to navigate and find tests.

---

## Coverage Priority

| Option | Description | Selected |
|--------|-------------|----------|
| ViewModel → Services → Integration | Start with SwitcherViewModel (100%), then services, then integration. Exclude Views/AppDelegate. | |
| Critical path first | Focus on enumeration + MRU logic first (highest risk), then ViewModel, then supporting services. | ✓ |
| Breadth-first approach | Basic tests for all components (50% across board), then deepen. Ensures nothing forgotten. | |

**User's choice:** Critical path first
**Notes:** Window enumeration (68% filtering bug) and MRU tracking are highest risk. Cover these first, then ViewModel state management, then supporting services. Target 60-80% overall coverage, 100% on business logic.

---

## Test Method Naming

| Option | Description | Selected |
|--------|-------------|----------|
| test_whenCondition_thenOutcome | Example: test_whenCycleNextCalled_thenSelectedIndexIncrements(). BDD-style, descriptive. | |
| testMethodName_condition() | Example: testCycleNext_incrementsIndex(). Shorter, still clear. | ✓ |
| testMethodName() only | Example: testCycleNext(). Minimal naming, relies on test body. | |

**User's choice:** testMethodName_condition()
**Notes:** Balance between descriptiveness and brevity. Common Swift testing pattern.

---

## Security Checks

| Option | Description | Selected |
|--------|-------------|----------|
| SwiftLint security rules | Force unwraps, weak crypto. Free via Homebrew action. Already planned Phase 3. | |
| Dependency scanning | Dependabot for SPM. Zero dependencies currently, minimal value. | |
| SAST | Semgrep, CodeQL (free for public repos). Scans for hardcoded secrets, injection. | |
| Skip for now | Security belongs in Phase 3 (QA) or Phase 5 (CI/CD). Focus test coverage in Phase 2. | ✓ |

**User's choice:** Skip for now
**Notes:** Security checks deferred to appropriate phases. Phase 2 is testing infrastructure only.

---

## Claude's Discretion

- Exact assertion helpers and test utilities implementation
- Test data fixtures structure (WindowInfo creation)
- XCTest setup/teardown patterns
- Async test handling for thumbnail capture completion

---

## Deferred Ideas

**Phase 3 (Quality Assurance):**
- SwiftLint security rules
- Static Application Security Testing (SAST)

**Phase 5 (Build & CI/CD):**
- GitHub Actions workflow running tests
- Dependabot dependency scanning
- Code coverage reporting in CI
