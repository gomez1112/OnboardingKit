# OnboardingKit

A production-ready, Apple-native SwiftUI onboarding package that automatically chooses between a first-launch walkthrough and a "What's New" feature sheet based on your app version. It is designed for modern SwiftUI apps with clean call sites, sensible defaults, and minimal boilerplate.

---

## Requirements
- Swift tools: **Swift 6.2**
- Platforms (from `Package.swift`): iOS **17+**, macOS **14+**, tvOS **17+**, watchOS **10+**

## Installation
Add **OnboardingKit** using Swift Package Manager:

1. In Xcode: **File → Add Package Dependencies…**
2. Paste the repository URL and add it to your target(s).
3. Import the library where needed:
   ```swift
   import OnboardingKit
   import SwiftUI
   ```

---

## Quick Start
1) **Create your first-launch pages**
```swift
let pages: [OnboardingPage] = [
    .init(
        title: "Welcome",
        description: "A quick tour to get you started.",
        systemImage: "sparkles",
        backgroundColor: .obk_systemBackground,
        iconColor: .blue
    ),
    .init(
        title: "Stay Organized",
        description: "Track what matters, effortlessly.",
        systemImage: "checklist",
        backgroundColor: .obk_systemBackground,
        iconColor: .green
    )
]
```

2) **Describe what's new for returning users**
```swift
let features: [FeatureItem] = [
    .init(
        title: "New Dashboard",
        description: "A cleaner overview with faster access to actions.",
        systemImage: "rectangle.3.group",
        backgroundColor: .obk_secondarySystemBackground,
        iconColor: .blue
    ),
    .init(
        title: "Better Search",
        description: "Find entries instantly with smarter filtering.",
        systemImage: "magnifyingglass",
        backgroundColor: .obk_secondarySystemBackground,
        iconColor: .purple
    )
]
```

3) **Wrap your root content**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingWrapper(
                currentVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
                pages: pages,
                features: features,
                tint: .blue
            ) {
                ContentView()
            }
        }
    }
}
```

OnboardingKit uses `OnboardingManager.storageKey` to remember the last seen version. First-time users see the walkthrough; returning users see "What's New" when the version changes.

---

## Customization
- **Accent color**: Pass a `tint` to `OnboardingWrapper` (default `.blue`).
- **Icons**: Use SF Symbols via `systemImage:` or asset names via `image:` on `OnboardingPage` and `FeatureItem`.
- **Backgrounds**: Apply per-page or per-feature backgrounds; the provided `Color.obk_systemBackground` helpers keep layouts consistent across Apple platforms.
- **Per-page actions**: Supply `actionTitle` and `action` when constructing `OnboardingPage` to run lightweight tasks (e.g., priming state) before advancing.
- **First-launch vs. What’s New**: Customize copy independently by editing `pages` and `features` arrays.

---

## Advanced Usage
- **Version strategy**: Provide any string to `currentVersion` (e.g., `"1.2.0 (45)"`) if you want build metadata to trigger the "What's New" sheet.
- **Manual presentation**: You can present `PagedOnboardingView` or `WelcomeSheetView` directly for custom flows; `OnboardingWrapper` simply orchestrates them for you.
- **Resetting**: Call `OnboardingManager.resetOnboarding()` during development or QA to force onboarding to show on next launch.
- **Testing**: Use `@testable import OnboardingKit` and verify storage interactions; the `storageKey` constant keeps test setup consistent.
- **Accessibility**: Buttons and indicators include accessibility labels; provide meaningful titles and descriptions so assistive technologies announce helpful context.

---

## FAQ
**How does OnboardingKit decide what to show?**

- If no version has been stored, `OnboardingWrapper` shows the first-launch pages.
- If the stored version differs from `currentVersion`, it shows the "What's New" sheet.
- Otherwise, your content renders without interruption.

**Can users dismiss the sheets?**

- On iOS, both onboarding experiences are non-dismissable by swipe; users complete the flow via the provided buttons.

**How do I localize strings?**

- Provide localized values for titles, descriptions, and button labels when constructing `OnboardingPage` and `FeatureItem` models.

**Does it work without assets?**

- Yes. Use SF Symbols for a zero-asset setup, or provide asset names if you prefer custom artwork.

---

## Migration Notes
- **v1 → v2 (DocC-ready)**: Public APIs now include DocC documentation comments for improved discoverability. Existing call sites remain source-compatible.
- **Custom "What's New" layouts**: If you previously duplicated logic to show release notes, prefer instantiating `WelcomeSheetView` directly so you keep a single source of truth for feature descriptions.
- **Testing helpers**: Use the shared `OnboardingManager.resetOnboarding()` instead of deleting defaults manually; this keeps behavior consistent with production logic.

---

## Contributing
Issues and pull requests are welcome. Please ensure changes include appropriate documentation updates and stay aligned with the supported platform versions above.
