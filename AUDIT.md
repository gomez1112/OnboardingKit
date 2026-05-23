# OnboardingKit Audit (2026-05-23)

## Bugs identified

1. **`ForEach(Array(features.enumerated()))` creates an unnecessary array copy** in `WelcomeSheetView`, which can cause avoidable allocations and stale identity behavior during rapid updates.
2. **Hard-coded user-facing strings** (Skip/Next/Get Started/Continue/What's New in) are scattered in views, making localization and product copy updates harder and error-prone.

## Improvements implemented

- Replaced `ForEach(Array(features.enumerated()), ...)` with `ForEach(features.enumerated(), ...)` to eliminate copying and align with modern SwiftUI iteration.
- Added a centralized `OnboardingCopy` model so all primary user-facing labels can be configured in one place.

## New feature added

- **Configurable onboarding copy API**: `OnboardingWrapper`, `PagedOnboardingView`, and `WelcomeSheetView` now accept `copy: OnboardingCopy` (defaulting to `.default`) so apps can localize and customize onboarding text without modifying library source.
