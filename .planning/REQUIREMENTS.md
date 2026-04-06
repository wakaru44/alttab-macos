# Requirements: AltTab Production Refactor

**Defined:** 2026-04-06
**Core Value:** Reliable window switching powered by maintainable, testable, well-documented code

## v1 Requirements

### Architecture & Code Quality

- [ ] **ARCH-01**: Refactor to Lightweight MVVM architecture pattern
- [ ] **ARCH-02**: Implement protocol-based abstractions for system APIs (WindowEnumerating, AccessibilityService, ThumbnailCapturing)
- [ ] **ARCH-03**: Apply constructor-based dependency injection throughout codebase
- [ ] **ARCH-04**: Implement Repository pattern for thumbnail caching
- [ ] **ARCH-05**: Establish clear separation: Views → ViewModels → Services
- [ ] **ARCH-06**: Apply Single Responsibility Principle (break up god objects like WindowModel)
- [ ] **ARCH-07**: Apply Open/Closed Principle (extend via protocols, not modification)
- [ ] **ARCH-08**: Apply Interface Segregation Principle (focused protocols, not fat interfaces)
- [ ] **ARCH-09**: Apply Dependency Inversion Principle (depend on abstractions, not concretions)
- [ ] **ARCH-10**: Use declarative over imperative style where appropriate
- [ ] **ARCH-11**: Apply functional patterns (railroad programming for composability)

### Window State Tracking

- [ ] **TRACK-01**: Track window focus changes in real-time (when user clicks/activates window)
- [ ] **TRACK-02**: Track window creation events (new windows appear)
- [ ] **TRACK-03**: Track window destruction events (windows close/terminate)
- [ ] **TRACK-04**: Track app activation events (user switches between apps)
- [ ] **TRACK-05**: Update MRU order immediately on any focus change
- [ ] **TRACK-06**: Implement AXObserver callbacks for intra-app window switching (e.g., Cmd+` between Terminal windows)
- [ ] **TRACK-07**: Implement NSWorkspace notifications for app-level lifecycle changes
- [ ] **TRACK-08**: Handle observer lifecycle (install on app launch, remove on terminate)
- [ ] **TRACK-09**: Maintain accurate MRU order across all tracking events
- [ ] **TRACK-10**: Ensure visible windows always prioritized over minimized in MRU

### Testing

- [ ] **TEST-01**: Create XCTest target in Xcode project
- [ ] **TEST-02**: Unit tests for all ViewModels (100% coverage target)
- [ ] **TEST-03**: Unit tests for window filtering logic
- [ ] **TEST-04**: Unit tests for window sorting (MRU + visibility priority)
- [ ] **TEST-05**: Unit tests for thumbnail cache repository
- [ ] **TEST-06**: Integration tests with mocked system APIs (WindowEnumerating, AccessibilityService)
- [ ] **TEST-07**: Integration tests for AXObserver event handling
- [ ] **TEST-08**: Integration tests for NSWorkspace notification handling
- [ ] **TEST-09**: Achieve 60-80% overall code coverage
- [ ] **TEST-10**: Add test execution to Makefile (`make test`)

### Documentation

- [ ] **DOCS-01**: Create Structurizr DSL workspace.dsl file
- [ ] **DOCS-02**: C1 diagram (System Context) showing AltTab and macOS system services
- [ ] **DOCS-03**: C2 diagram (Container) showing ViewModels, Services, Views, Repositories
- [ ] **DOCS-04**: C3 diagram (Component) showing detailed class relationships and dependencies
- [ ] **DOCS-05**: Complete docstrings for all public APIs (classes, protocols, methods)
- [ ] **DOCS-06**: Rationale comments explaining WHY for complex logic (not WHAT)
- [ ] **DOCS-07**: Architecture documentation in `.planning/architecture/` directory
- [ ] **DOCS-08**: README.md with project overview, build instructions, architecture summary

### Quality Assurance

- [ ] **QA-01**: Add SwiftLint configuration (.swiftlint.yml)
- [ ] **QA-02**: Fix all SwiftLint violations (0 warnings target)
- [ ] **QA-03**: Configure static analysis in Xcode project
- [ ] **QA-04**: Fix window enumeration filtering bug (currently filters 68% of windows)
- [ ] **QA-05**: Fix expensive permission polling bug (60% CPU from SCShareableContent.current)
- [ ] **QA-06**: Ensure no force unwraps (replace with guard/if let or document why safe)
- [ ] **QA-07**: Configure vulnerability scanning (via GitHub Dependabot or similar)
- [ ] **QA-08**: Zero known bugs/defects at completion

### Build & CI/CD

- [ ] **BUILD-01**: Separate Debug build configuration with logging enabled
- [ ] **BUILD-02**: Separate Release build configuration with optimizations
- [ ] **BUILD-03**: Create GitHub Actions workflow file (.github/workflows/ci.yml)
- [ ] **BUILD-04**: CI runs tests on every push
- [ ] **BUILD-05**: CI runs SwiftLint on every push
- [ ] **BUILD-06**: CI runs static analysis
- [ ] **BUILD-07**: CI fails if tests fail or coverage drops below 60%

### Assets

- [ ] **ASSET-01**: Design app icon concept (512x512 base)
- [ ] **ASSET-02**: Generate icon via Gemini prompts
- [ ] **ASSET-03**: Create all required icon sizes (16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024)
- [ ] **ASSET-04**: Integrate icons into Assets.xcassets
- [ ] **ASSET-05**: Keep existing SF Symbols menu bar icon (no changes needed)

## Out of Scope

| Feature | Reason |
|---------|--------|
| New features beyond existing capabilities | Refactor only, preserve current functionality |
| Backward compatibility | Brand new software, never deployed, no users to break |
| iOS/iPadOS ports | macOS-only utility |
| SwiftUI migration | AppKit works fine, migration adds risk without benefit |
| Sandboxing | Requires entitlements that conflict with Accessibility/ScreenCaptureKit |
| Third-party dependencies | Pure native frameworks only, keep app lightweight |
| OAuth/cloud sync | Local-only utility, no network requirements |
| Localization | English-only for v1 |
| Sparkle auto-updates | Manual distribution for now |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (To be filled by roadmapper) | | |

**Coverage:**
- v1 requirements: 41 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 41 ⚠️

---
*Requirements defined: 2026-04-06*
*Last updated: 2026-04-06 after initial definition*
