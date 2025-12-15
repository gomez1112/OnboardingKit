# OnboardingKit

A small, “Apple-native” SwiftUI onboarding package that handles:

- **First launch onboarding** (paged walkthrough)
- **What’s New** sheet (feature list)
- Automatic display logic based on **app versioning**
- Lightweight **reset** API for debugging and QA

Designed for modern SwiftUI apps with clean call sites and minimal setup.

---

## Requirements

- Swift tools: **Swift 6.2**
- Platforms (from Package.swift):
  - iOS **17+**
  - macOS **14+**
  - tvOS **17+**
  - watchOS **10+**

---

## Installation

### Swift Package Manager (Xcode)

1. In Xcode: **File → Add Package Dependencies…**
2. Paste your repository URL
3. Add **OnboardingKit** to your target(s)

Then import:

```swift
import OnboardingKit
import SwiftUI
```

---

## Quick Start

### 1) Define your pages (first launch)

```swift
import SwiftUI
import OnboardingKit

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

### 2) Define “What’s New” features (new version)

```swift
import SwiftUI
import OnboardingKit

let features: [FeatureItem] = [
    .init(
        title: "New Dashboard",
        description: "A cleaner overview with faster access to actions.",
        systemImage: "rectangle.3.group",
        backgroundColor: Color.obk_secondarySystemBackground,
        iconColor: .blue
    ),
    .init(
        title: "Better Search",
        description: "Find entries instantly with smarter filtering.",
        systemImage: "magnifyingglass",
        backgroundColor: Color.obk_secondarySystemBackground,
        iconColor: .purple
    )
]
```

### 3) Wrap your app content

`OnboardingWrapper` decides which UI to show based on `lastSeenVersion`:

- If the user has **never seen onboarding** → **First Launch**
- If the version **changed** → **What’s New**
- Otherwise → show content normally

```swift
import SwiftUI
import OnboardingKit

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

---

## Core API

### `OnboardingWrapper`

```swift
public struct OnboardingWrapper<Content: View>: View
```

**Parameters**

- `appName`: defaults to `CFBundleName` (fallback `"App"`)
- `currentVersion`: the version string you want to track
- `pages`: the content for first launch onboarding
- `features`: the content for “What’s New”
- `tint`: your primary accent color
- `content`: your app’s root content

**Behavior**

- Uses `@AppStorage(OnboardingManager.storageKey)` to persist the last seen version
- Presents onboarding using `.sheet(...)`
- Uses:
  - `PagedOnboardingView` for first launch
  - `WelcomeSheetView` for “What’s New”

---

### `OnboardingPage`

Your “walkthrough page” model (Sendable & Equatable):

```swift
public struct OnboardingPage: Identifiable, Equatable, Sendable
```

**Constructors**

- System image:

```swift
OnboardingPage(
    title: "Title",
    description: "Description",
    systemImage: "sparkles",
    backgroundColor: .clear,
    iconColor: .blue
)
```

- Asset image:

```swift
OnboardingPage(
    title: "Title",
    description: "Description",
    image: "MyAsset",
    backgroundColor: .clear,
    iconColor: .blue
)
```

- With a custom action and button title:

```swift
OnboardingPage(
    title: "Enable Notifications",
    description: "Get reminders when it matters.",
    systemImage: "bell.badge",
    backgroundColor: .clear,
    iconColor: .orange,
    actionTitle: "Allow",
    action: {
        // Do something lightweight (e.g. toggle a setting)
    }
)
```

> **Tip:** If your action touches UI state or actor-isolated data, ensure it runs on the right actor. The model stores the closure as `@Sendable () -> Void`.

---

### `FeatureItem`

Your “What’s New” row model:

```swift
public struct FeatureItem: Identifiable, Equatable, Sendable
```

Includes:
- `title`, `description`
- `icon` (`.system` or `.asset`)
- `backgroundColor` (for card styling)
- `iconColor` (optional override)

---

### `OnboardingManager`

A tiny “control center”:

```swift
public enum OnboardingManager {
    static let storageKey = "com.onboardingkit.lastSeenVersion"
    public static func resetOnboarding()
}
```

**Reset onboarding (debug / QA):**

```swift
import OnboardingKit

OnboardingManager.resetOnboarding()
```

This clears `lastSeenVersion`, causing first launch onboarding to appear again next app run.

---

## Views

### `PagedOnboardingView`

A paged walkthrough with:

- Platform-appropriate paging:
  - `TabView(.page)` on iOS/tvOS/watchOS
  - manual transitions on macOS
- Skip button logic (hidden on last page)
- Bottom page indicators + “Next / Get Started” button
- Uses `.safeAreaInset` for top/bottom controls (no hard-coded safe-area padding)

You typically don’t present this directly—`OnboardingWrapper` handles it.

---

### `WelcomeSheetView`

A “What’s New” sheet with:

- Animated title + feature cards
- A primary “Continue” button
- `.interactiveDismissDisabled()` on iOS (so users complete the flow)

Also typically presented via `OnboardingWrapper`.

---

## Cross-Platform Color Helpers

To avoid `UIColor` issues on macOS, the package includes a small shim:

```swift
Color.obk_systemBackground
Color.obk_secondarySystemBackground
```

Use these in your pages/features so your backgrounds look correct across platforms.

---

## Versioning Tips

OnboardingKit compares `lastSeenVersion` to your `currentVersion`.

Recommended source:

```swift
let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
```

If you want “What’s New” to also show on build changes, you can use:

```swift
let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
```

Or combine both (e.g. `"1.2.0 (45)"`).

---

## Testing

This package is friendly to **Swift Testing** (`import Testing`) and XCTest.

### Swift Testing example

```swift
import Testing
@testable import OnboardingKit

@Test func onboardingResetClearsStoredVersion() async throws {
    // Arrange: set a value
    UserDefaults.standard.set("1.0", forKey: OnboardingManager.storageKey)

    // Act
    OnboardingManager.resetOnboarding()

    // Assert
    #expect(UserDefaults.standard.string(forKey: OnboardingManager.storageKey) == nil)
}
```

> If you prefer, you can wrap UserDefaults access behind a small abstraction for easier testing. The package keeps things intentionally simple.

---

## Progressive Disclosure

Use it in layers:

1. Start with **`OnboardingWrapper`** (one-line integration)
2. Customize the UI by editing your **pages/features**
3. Use **action pages** only when you need per-page actions
4. Call `resetOnboarding()` for debugging, QA, and demo flows

