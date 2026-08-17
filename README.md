# OnboardingKit

[![Swift Package Index](https://img.shields.io/badge/Swift%20Package%20Index-compatible-brightgreen)](https://swiftpackageindex.com/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20visionOS%201-blue)](#requirements)

OnboardingKit is a dependency-free SwiftUI package for accessible first-launch onboarding, release highlights, and interactive setup.

## Requirements

- Swift 6.2 with strict concurrency
- iOS 17+, macOS 14+, or visionOS 1+

## Installation

Add this repository as a Swift Package dependency and `import OnboardingKit`.

## A basic flow

```swift
import OnboardingKit
import SwiftUI

struct WelcomeFlow: View {
    var body: some View {
        OnboardingFlow {
            OnboardingStep.welcome(
                id: "welcome",
                title: "Welcome",
                subtitle: "A quick introduction.",
                systemImage: "sparkles"
            )
            OnboardingStep.features(
                id: "features",
                title: "Highlights",
                features: [
                    .init(title: "Private", systemImage: "lock"),
                    .init(title: "Fast", systemImage: "bolt")
                ]
            )
        }
    }
}
```

Copy and step text use `LocalizedStringResource`. Package defaults resolve from OnboardingKit's English localization; literals supplied by an app resolve in that app's localization context.

## Interactive steps

Report custom validation from the custom subtree. A required step with no report defaults to complete; a reported `false` disables its primary control. Skipping an optional step never invokes `beforeAdvance`.

```swift
OnboardingFlow(
    onError: { error in await analytics.record(error) },
    onStepAppear: { stepID in await analytics.recordImpression(stepID) }
) {
    OnboardingStep.custom(
        id: "notifications",
        title: "Notifications",
        isRequired: false,
        beforeAdvance: { try await requestNotificationPermission() }
    )
} customContent: { step in
    NotificationOptionsView()
        .onboardingStepComplete(step.id == "notifications" && selectionIsValid)
}
```

A thrown `beforeAdvance` error vetoes navigation and is passed to `onError`.

## Version-aware presentation

`OnboardingWrapper` reads `CFBundleShortVersionString` by default, stores completion under the stable `OnboardingManager.storageKey`, and presents first-launch or numerically newer release content. Supply `suiteName` for an App Group or other `UserDefaults` suite.

```swift
OnboardingWrapper(
    suiteName: "group.com.example.app",
    presentationStyle: .automatic,
    interactiveDismissDisabled: true,
    storesVersionOnCancel: false
) {
    ContentView()
} firstLaunchSteps: {
    .welcome(id: "welcome", title: "Welcome", subtitle: "Let's begin.", systemImage: "sparkles")
} whatsNewSteps: {
    .features(id: "release", title: "What's New", features: [.init(title: "Faster Search", systemImage: "magnifyingglass")])
}
```

`.automatic` uses full-screen presentation in a compact horizontal size class and a sheet in a regular size class. Choose `.sheet` or `.fullScreen` to override it. Cancelling does **not** store the version by default, so the flow can return on next launch; set `storesVersionOnCancel: true` to record it. Completing always records the current version.

When `tint` is omitted, controls inherit an upstream `.tint(...)`, falling back to the app accent color. Asset icons accept `bundleIdentifier` for modular catalogs:

```swift
let icon = OnboardingIcon.asset("WelcomeArt", bundleIdentifier: "com.example.Features")
```

## Migrating from 1.x

Version 2 is source breaking. In particular, replace `String` copy with `LocalizedStringResource`, change `beforeAdvance` to `async throws`, replace `isComplete` with `.onboardingStepComplete(...)`, remove `appName`, and update asset-icon patterns for the bundle-identifier associated value. tvOS and watchOS are no longer supported. See [CHANGELOG.md](CHANGELOG.md) and the DocC article **Migrating from 1.x** for the full list.

## Accessibility

The flow exposes localized progress, moves VoiceOver focus to each new title, marks titles as headers, announces asynchronous work, preserves 44-point navigation targets, supports Reduce Motion, and uses Dynamic Type text styles.
