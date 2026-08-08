# OnboardingKit

OnboardingKit is a SwiftUI package for first-launch onboarding, release highlights, and interactive setup. Every experience is built from the same `OnboardingFlow` and `OnboardingStep` APIs.

## Requirements

- Swift 6.2+
- iOS 26+, macOS 26+, tvOS 26+, or watchOS 26+

## Installation

Add this repository as a Swift Package dependency, then import the library:

```swift
import OnboardingKit
import SwiftUI
```

## Start with a flow

Welcome and feature flows need only their steps. Completion, cancellation, skipping, copy, tint, progress, and custom content all have sensible defaults.

```swift
OnboardingFlow {
    OnboardingStep.welcome(
        id: "welcome",
        title: "Welcome",
        subtitle: "A quick intro.",
        systemImage: "sparkles"
    )

    OnboardingStep.features(
        id: "features",
        title: "What You Can Do",
        features: [
            .init(title: "Track", systemImage: "checkmark.circle"),
            .init(title: "Reflect", systemImage: "sun.max")
        ]
    )
}
```

### Add custom setup only when needed

Use `.custom` for interactive app-specific steps. A required step can provide `isComplete` to control when its primary button becomes available, while an optional step displays the skip action. All callbacks support Swift concurrency.

```swift
OnboardingFlow(
    tint: .orange,
    progressStyle: .fraction,
    onComplete: { await saveOnboarding() },
    onCancel: { await recordCancellation() },
    onSkip: { stepID in await recordSkip(stepID) }
) {
    OnboardingStep.welcome(
        id: "welcome",
        title: "Welcome",
        subtitle: "Let's personalize your experience.",
        systemImage: "sparkles"
    )

    OnboardingStep.custom(
        id: "goals",
        title: "Choose Your Goals",
        isRequired: true,
        isComplete: { !selectedGoals.isEmpty }
    )
} customContent: { step in
    switch step.id {
    case "goals":
        GoalSelectionView(selectedGoals: $selectedGoals)
    default:
        EmptyView()
    }
}
```

If a custom step has no matching content, the flow safely renders an empty body and keeps the standard header and controls.

## Automatic version-aware presentation

`OnboardingWrapper` stores `currentVersion` under `OnboardingManager.storageKey`. It presents first-launch steps when nothing is stored, presents the release flow after a version change, and otherwise shows app content directly.

### First launch

```swift
OnboardingWrapper(currentVersion: currentVersion) {
    ContentView()
} firstLaunchSteps: {
    OnboardingStep.welcome(
        id: "welcome",
        title: "Welcome",
        subtitle: "A quick intro.",
        systemImage: "sparkles"
    )
    OnboardingStep.features(
        id: "features",
        title: "Get Started",
        features: [.init(title: "Track progress", systemImage: "chart.line.uptrend.xyaxis")]
    )
}
```

### First launch and What's New

Add the second step builder only when the app has release highlights to show:

```swift
OnboardingWrapper(currentVersion: currentVersion) {
    ContentView()
} firstLaunchSteps: {
    OnboardingStep.welcome(
        id: "welcome",
        title: "Welcome",
        subtitle: "A quick intro.",
        systemImage: "sparkles"
    )
} whatsNewSteps: {
    OnboardingStep.features(
        id: "release-highlights",
        title: "What's New",
        features: [.init(title: "Faster search", systemImage: "magnifyingglass")]
    )
}
```

An empty applicable builder does not present a blank sheet: the wrapper records the current version and continues. An empty manually requested flow clears the request without changing stored completion state.

### Advanced wrapper

```swift
@State private var presentation: OnboardingPresentation?

OnboardingWrapper(
    appName: "Momenta",
    currentVersion: currentVersion,
    tint: .orange,
    progressStyle: .dots,
    copy: OnboardingCopy(
        skipButtonTitle: "Not Now",
        nextButtonTitle: "Continue",
        getStartedButtonTitle: "Start"
    ),
    presentation: $presentation,
    onComplete: { await analytics.trackOnboardingCompleted() },
    onSkip: { stepID in await analytics.trackSkippedStep(stepID) },
    onCancel: { await analytics.trackCancelled() }
) {
    ContentView()
} firstLaunchSteps: {
    OnboardingStep.welcome(
        id: "welcome",
        title: "Welcome",
        subtitle: "A quick intro.",
        systemImage: "sparkles"
    )
    OnboardingStep.custom(id: "goals", title: "Choose Your Goals")
} whatsNewSteps: {
    OnboardingStep.features(
        id: "release-highlights",
        title: "What's New",
        features: [.init(title: "New insights", systemImage: "lightbulb")]
    )
} customContent: { step in
    switch step.id {
    case "goals":
        GoalSelectionView()
    default:
        EmptyView()
    }
}
```

Set the binding to `.firstLaunch` or `.whatsNew` to replay either configured flow. Completing any presented flow stores the current version before invoking `onComplete`. Cancelling clears manual presentation without recording completion.

## API overview

- `OnboardingFlow`: presents a resolved sequence of onboarding steps.
- `OnboardingStep.welcome`: displays an introduction and icon.
- `OnboardingStep.features`: displays rows of feature highlights.
- `OnboardingStep.custom`: embeds app-specific content with optional validation and async actions.
- `OnboardingProgressStyle`: chooses dots, a fraction, or hidden progress.
- `OnboardingCopy`: customizes shared control labels.
- `OnboardingWrapper`: automatically selects first-launch or release steps from the stored app version.
- `OnboardingPresentation`: manually requests one of the wrapper's configured flows.
- `OnboardingManager.resetOnboarding()`: clears the stored version for development, QA, or an app-provided reset action.

## Accessibility

Use descriptive step and feature titles, verify layouts at accessibility Dynamic Type sizes, and use meaningful SF Symbols or assets. OnboardingKit uses semantic text styles, honors system tint behavior, and keeps decorative imagery out of the accessibility tree.
