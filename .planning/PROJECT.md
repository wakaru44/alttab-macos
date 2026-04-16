# AltTab for macOS - Production Grade Refactor

## What This Is

A Windows-style window switcher for macOS that is being transformed from a working prototype into production-grade software. AltTab provides keyboard-driven window switching with thumbnail previews, MRU ordering, and system permissions management. This project refactors the existing codebase to achieve professional quality standards: clean architecture, comprehensive testing, complete documentation, and automated quality assurance.

## Core Value

Reliable window switching powered by maintainable, testable, well-documented code that can evolve confidently without breaking.

## Requirements

### Validated

These capabilities already exist in the codebase and must be preserved:

- ✓ Hotkey-based window switching (Cmd+Tab style) — existing
- ✓ Window enumeration with thumbnail capture — existing
- ✓ MRU (Most Recently Used) ordering — existing (bug fixed)
- ✓ Settings window for permissions management — existing
- ✓ Menu bar integration with SF Symbols icon — existing
- ✓ Thumbnail caching for performance — existing
- ✓ Graceful degradation when Screen Recording denied — existing

### Active

Quality improvements and infrastructure to achieve production grade:

**Architecture & Code Quality:**
- [ ] Clean architecture with SOLID principles (Lightweight MVVM + Protocol Abstractions)
- [ ] Protocol-based system API abstractions (WindowEnumerating, AccessibilityService, ThumbnailCapturing)
- [ ] Dependency injection via constructor injection
- [ ] Clear separation of concerns (Views → ViewModels → Services)
- [ ] Declarative, functional style where appropriate
- [ ] Repository pattern for thumbnail caching

**Testing:**
- [x] 60-80% test coverage (unit + integration) — Validated in Phase 2: Testing Infrastructure
- [x] Unit tests for all ViewModels and business logic — Validated in Phase 2: Testing Infrastructure
- [x] Integration tests with mocked system APIs — Validated in Phase 2: Testing Infrastructure
- [x] Test infrastructure and test targets in Xcode — Validated in Phase 2: Testing Infrastructure

**Documentation:**
- [ ] C4 architecture diagrams (Context, Container, Component) in Structurizr DSL
- [ ] Complete docstrings for all public APIs
- [ ] Rationale comments explaining WHY for complex logic
- [ ] Architecture documentation in `.planning/architecture/`

**Quality Assurance:**
- [x] SwiftLint configuration and all violations fixed — Validated in Phase 3: Quality Assurance
- [x] Static analysis integrated — Validated in Phase 3: Quality Assurance
- [ ] Vulnerability scanning configured (deferred to Phase 5 per D-24)
- [x] Zero known bugs/defects — Validated in Phase 3: Quality Assurance (P1/P2 bugs fixed)

**Build & CI/CD:**
- [ ] Separate Debug and Release build configurations
- [ ] GitHub Actions CI pipeline
- [ ] Automated tests on every commit
- [ ] Linting and static analysis in CI

**Assets:**
- [ ] Proper app icon for bundle/App Store (512x512 + all sizes)
- [ ] Icon generated via Gemini prompts
- [ ] Keep existing SF Symbols menu bar icon

### Out of Scope

- New features beyond existing capabilities — refactor only, no feature additions
- Backward compatibility concerns — brand new software, never deployed
- iOS/iPadOS versions — macOS only
- SwiftUI migration — stay with AppKit for now
- Sandboxing — requires too many entitlements that conflict with core functionality

## Context

**Existing Codebase:**
- 11 Swift source files in `AltTab/AltTab/`
- Pure AppKit (no SwiftUI)
- macOS 14.0+ target (Sonoma/Sequoia)
- Zero external dependencies (only native frameworks)
- Ad-hoc signing for development (causes TCC permission issues)

**Current Architecture Issues:**
- Imperative style with nested guard statements
- No dependency injection
- No protocol abstractions for system APIs
- Tight coupling between layers
- `WindowModel` is a god object (enumeration + filtering + sorting + MRU + observers)

**Known Technical Debt:**
- Zero test coverage (resolved in Phase 2)
- No static analysis or linting (resolved in Phase 3)
- Missing documentation
- Window filtering too aggressive (resolved in Phase 3 — debug logging added, PID-only self-filter)
- Permission polling expensive (resolved in Phase 3 — timer removed, manual refresh button)
- Uses private SPI `_AXUIElementGetWindow` (risky but necessary)

**System Integration Challenges:**
- Requires Accessibility permission (mandatory)
- Requires Screen Recording permission (optional, for thumbnails)
- TCC (Transparency, Consent, and Control) issues with ad-hoc signing
- Must integrate with CGWindowList, AXUIElement, ScreenCaptureKit

**Development Philosophy:**
- Clean code principles
- Semantics over syntax
- Functional programming patterns (railroad programming for composability)
- Object-oriented design patterns where appropriate
- SOLID principles throughout
- Declarative over imperative
- Minimal imperative code (only within method implementations)

## Constraints

- **Timeline**: Couple of days (aggressive but focused scope)
- **Platform**: macOS 14.0+ only (Sonoma/Sequoia)
- **Language**: Swift 5.9+ with AppKit
- **Architecture**: Lightweight MVVM + Protocol Abstractions (decided)
- **Test Coverage**: 60-80% minimum acceptable range
- **No New Features**: Refactor and quality only, preserve existing functionality
- **No Framework Dependencies**: Pure native macOS frameworks only
- **Private API Dependency**: Must use `_AXUIElementGetWindow` SPI (no public alternative exists)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Lightweight MVVM + Protocol Abstractions | Small app (~11 files) needs structure without overkill. MVVM enables testability. Protocol abstractions mock system APIs. | — Pending |
| Skip Coordinator pattern | Only 2 windows (switcher + settings), navigation too simple to justify pattern | — Pending |
| Constructor-based DI | App size doesn't warrant DI framework. Constructor injection sufficient. | — Pending |
| Repository pattern for caching | Abstracts NSCache, enables testing, allows future storage changes | — Pending |
| Stay with AppKit | SwiftUI migration out of scope, AppKit works fine for utility app | — Pending |
| Keep private SPI `_AXUIElementGetWindow` | No public API alternative exists for mapping AXUIElement → CGWindowID | — Pending |
| Structurizr DSL in workspace.dsl | Compatible with Docker self-hosted option, C1-C3 diagrams only | — Pending |
| GitHub Actions for CI | Standard choice, native macOS runner support | — Pending |

---
*Last updated: 2026-04-16 after Phase 3 completion*
