# Roadmap: AltTab Production Refactor

## Overview

Transform AltTab from working prototype to production-grade macOS utility through systematic refactoring. Five phases deliver clean architecture, comprehensive testing, quality assurance, complete documentation, and professional build pipeline while preserving all existing functionality.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Architecture Foundation** - Refactor to MVVM with protocol abstractions and robust window tracking
- [ ] **Phase 2: Testing Infrastructure** - Build comprehensive test coverage with unit and integration tests
- [ ] **Phase 3: Quality Assurance** - Fix bugs, eliminate violations, achieve zero defects
- [ ] **Phase 4: Documentation** - Complete architecture diagrams, docstrings, and developer docs
- [ ] **Phase 5: Build & Assets** - Professional CI/CD pipeline and app icon design

## Phase Details

### Phase 1: Architecture Foundation
**Goal**: Refactor existing code to clean MVVM architecture with protocol abstractions and accurate real-time window tracking
**Depends on**: Nothing (first phase)
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04, ARCH-05, ARCH-06, ARCH-07, ARCH-08, ARCH-09, ARCH-10, ARCH-11, TRACK-01, TRACK-02, TRACK-03, TRACK-04, TRACK-05, TRACK-06, TRACK-07, TRACK-08, TRACK-09, TRACK-10
**Success Criteria** (what must be TRUE):
  1. WindowModel god object is decomposed into focused services following Single Responsibility Principle
  2. System APIs (WindowEnumerating, AccessibilityService, ThumbnailCapturing) are abstracted behind protocols
  3. All dependencies injected via constructors, no global state or singletons remain
  4. Views depend only on ViewModels, ViewModels depend only on Services (clear layer separation)
  5. MRU order updates immediately when user switches windows or apps, reflecting accurate real-time state
  6. Window focus changes, creation, destruction, and app activation events tracked via AXObserver and NSWorkspace
**Plans**: 4 plans

Plans:
- [x] 01-01-PLAN.md — Define protocol abstractions and create AccessibilityService, WindowEnumerationService, ThumbnailRepository
- [x] 01-02-PLAN.md — Extract MRUTracker and WindowTracker with AXObserver/NSWorkspace tracking
- [x] 01-03-PLAN.md — Refactor WindowCapture/WindowActivator to protocol DI, create SwitcherViewModel
- [x] 01-04-PLAN.md — Wire DI composition root in AppDelegate, remove WindowModel god object

### Phase 2: Testing Infrastructure
**Goal**: Establish comprehensive test coverage with mocked system APIs enabling confident refactoring
**Depends on**: Phase 1
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08, TEST-09, TEST-10
**Success Criteria** (what must be TRUE):
  1. XCTest target exists in Xcode project and executes via Makefile
  2. All ViewModels have 100% unit test coverage with mocked service dependencies
  3. Window filtering logic (layer checks, bounds validation) has comprehensive unit tests
  4. Window sorting (MRU priority, visible-over-minimized) has unit tests covering all edge cases
  5. Integration tests verify AXObserver callbacks and NSWorkspace notifications update MRU correctly
  6. Code coverage reports show 60-80% overall coverage minimum
**Plans**: 4 plans

Plans:
- [x] 02-01-PLAN.md — Create XCTest target, mock implementations for all 6 protocols, and test helpers
- [x] 02-02-PLAN.md — Unit tests for MRUTracker and WindowEnumerationService (filtering/sorting)
- [x] 02-03-PLAN.md — Unit tests for SwitcherViewModel, ThumbnailRepository, WindowActivator
- [x] 02-04-PLAN.md — Integration tests for observer lifecycle, enumeration pipeline, coverage setup

### Phase 3: Quality Assurance
**Goal**: Achieve zero defects, zero violations, and fix all known bugs
**Depends on**: Phase 2
**Requirements**: QA-01, QA-02, QA-03, QA-04, QA-05, QA-06, QA-07, QA-08
**Success Criteria** (what must be TRUE):
  1. SwiftLint runs clean with zero warnings on all source files
  2. Window enumeration shows all valid windows (fix 68% filtering issue)
  3. Permission polling eliminated, no more expensive SCShareableContent.current calls in timer
  4. No force unwraps remain except where documented safe with rationale comments
  5. Static analysis shows zero warnings in Xcode
  6. All known bugs from CONCERNS.md are resolved and verified with tests
**Plans**: 3 plans

Plans:
- [x] 03-01-PLAN.md — SwiftLint configuration, fix all lint violations, replace force unwraps
- [x] 03-02-PLAN.md — Fix window filtering, eliminate permission polling, hotkey thread safety
- [x] 03-03-PLAN.md — Enable Xcode static analysis, warnings-as-errors, end-to-end QA verification

### Phase 4: Documentation
**Goal**: Complete architecture documentation, API docs, and developer onboarding materials
**Depends on**: Phase 3
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05, DOCS-06, DOCS-07, DOCS-08
**Success Criteria** (what must be TRUE):
  1. Structurizr DSL workspace.dsl file exists with C1 (System Context), C2 (Container), C3 (Component) diagrams
  2. All public APIs (classes, protocols, methods) have complete docstring documentation
  3. Complex logic sections have rationale comments explaining WHY decisions were made
  4. README.md exists with project overview, build instructions, permissions setup, and architecture summary
  5. .planning/architecture/ directory contains up-to-date architecture documentation
**Plans**: TBD

Plans:
- [ ] 04-01: TBD during planning

### Phase 5: Build & Assets
**Goal**: Production-ready build configurations, CI pipeline, and professional app icon
**Depends on**: Phase 4
**Requirements**: BUILD-01, BUILD-02, BUILD-03, BUILD-04, BUILD-05, BUILD-06, BUILD-07, ASSET-01, ASSET-02, ASSET-03, ASSET-04, ASSET-05
**Success Criteria** (what must be TRUE):
  1. Debug and Release build configurations work with appropriate compiler flags and optimizations
  2. GitHub Actions CI runs on every push and fails if tests fail or coverage drops below 60%
  3. CI pipeline runs SwiftLint and static analysis automatically
  4. Professional app icon (512x512 base with all sizes) integrated into Assets.xcassets
  5. App builds and runs correctly with new icon visible in Finder and Applications folder
**Plans**: TBD

Plans:
- [ ] 05-01: TBD during planning

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Architecture Foundation | 4/4 | Complete | - |
| 2. Testing Infrastructure | 0/4 | Planned | - |
| 3. Quality Assurance | 0/3 | Planned | - |
| 4. Documentation | 0/TBD | Not started | - |
| 5. Build & Assets | 0/TBD | Not started | - |
