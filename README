# OnboardingKit

OnboardingKit is a small, opinionated SwiftUI package that gives your app a polished onboarding experience and a “What’s New” sheet with **minimal setup**.

It’s designed to be:

- 🧱 **Drop-in** – wrap your root view and you’re done  
- 🧭 **Version-aware** – shows onboarding on first launch, “What’s New” on updates  
- 🎨 **Beautiful by default** – animated pages, indicators, and feature cards  
- 🖥️ **Multiplatform** – iOS, macOS, tvOS, watchOS (SwiftUI)

---

## Features

- **Paged onboarding flow** (`PagedOnboardingView`)
  - Animated title, description, and icon
  - Page indicators and a primary CTA button
  - Per-page background & icon colors
  - Optional per-page custom button title and action

- **“What’s New” sheet** (`WelcomeSheetView`)
  - Title section (“What’s New in …”)
  - Scrollable list of feature cards (`FeatureItem`)
  - Smooth entrance animations
  - Single “Continue” action button

- **Smart wrapper** (`OnboardingWrapper`)
  - Automatically decides whether to show:
    - First-launch onboarding; or
    - “What’s New” updates
  - Uses `@AppStorage` to track the last seen version
  - Never shows an empty / blank sheet (has a safe fallback)

- **Simple models**
  - `OnboardingPage` – describes each onboarding page
  - `FeatureItem` – describes each “What’s New” feature
  - `OnboardingIcon` – enum to support SF Symbols or asset images

---

## Requirements

- **Swift**: 6.2+
- **Platforms**:
  - iOS 17+
  - macOS 14+
  - tvOS 17+
  - watchOS 10+

(See `Package.swift` for the exact platform configuration.)

---

## Installation

### Swift Package Manager (Xcode)

1. In Xcode, go to  
   **File → Add Packages…**
2. Enter the repository URL for OnboardingKit (your GitHub URL here).
3. Choose `OnboardingKit` and add it to your app target.

### Swift Package Manager (Package.swift)

Add OnboardingKit to your package dependencies and target:

```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/your-username/OnboardingKit.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "OnboardingKit", package: "OnboardingKit")
        ]
    )
]

import SwiftUI
import OnboardingKit

let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        title: "Welcome to MyApp",
        description: "Stay on top of your tasks with a clean and focused interface.",
        systemImage: "sparkles",
        backgroundColor: .blue.opacity(0.1),
        iconColor: .blue
    ),
    OnboardingPage(
        title: "Sync Across Devices",
        description: "Your data is securely synced across iPhone, iPad, and Mac.",
        systemImage: "icloud",
        backgroundColor: .purple.opacity(0.1),
        iconColor: .purple
    ),
    OnboardingPage(
        title: "Ready to Start?",
        description: "Customize your preferences and start being productive today.",
        systemImage: "hand.thumbsup.fill",
        backgroundColor: .green.opacity(0.1),
        iconColor: .green,
        actionTitle: "Let’s Go",
        action: {
            // Optional per-page action before finishing
            print("Final onboarding page action tapped")
        }
    )
]


let whatsNewFeatures: [FeatureItem] = [
    FeatureItem(
        title: "Widgets",
        description: "Add MyApp widgets to your Home Screen for quick access.",
        systemImage: "rectangle.stack.badge.plus",
        backgroundColor: .orange.opacity(0.1),
        iconColor: .orange
    ),
    FeatureItem(
        title: "New Themes",
        description: "Choose from new light, dark, and high-contrast themes.",
        systemImage: "paintpalette.fill",
        backgroundColor: .pink.opacity(0.1),
        iconColor: .pink
    )
]
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingWrapper(
                currentVersion: "1.0.0",         // <- bump this on each release
                pages: onboardingPages,
                features: whatsNewFeatures,
                tint: .blue                      // global accent for onboarding UI
            ) {
                // Your real app content
                RootContentView()
            }
        }
    }
}
```

MIT License

Copyright (c) 2025 Gerard Gomez
...

