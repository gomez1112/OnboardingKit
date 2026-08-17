# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This project uses Semantic Versioning.

## [2.0.0] - 2026-08-17

### Added
- Testable observable flow model, error and step-appearance callbacks, completion preferences, injected UserDefaults suites, presentation styles, localized resources, DocC documentation, previews, and accessibility focus/progress support.
- Asset icons can resolve a consumer-supplied bundle identifier.

### Changed
- Minimum platforms are iOS 17, macOS 14, and visionOS 1; tvOS and watchOS are no longer supported.
- All visible copy and step/feature text use `LocalizedStringResource` rather than `String`.
- `beforeAdvance` is now `async throws` and errors veto navigation.
- Feature identity is deterministic and string based rather than UUID based.
- Tint inherits the environment when omitted, version defaults from the main bundle, and wrapper presentation is size-class aware.
- Version decisions only show What's New for numeric upgrades, not downgrades.

### Removed
- `OnboardingStep.isComplete`; custom content now reports state with `onboardingStepComplete(_:)`.
- The wrapper's `appName` parameter.
- Dead platform color shims and conditional view helpers.
