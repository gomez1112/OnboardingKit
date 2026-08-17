# Migrating from 1.x

Version 2 removes tvOS and watchOS, changes visible `String` properties to `LocalizedStringResource`, makes `beforeAdvance` throwing, replaces `isComplete` with `onboardingStepComplete(_:)`, changes asset icons to carry an optional bundle identifier, removes wrapper `appName`, makes `currentVersion` optional, and adds optional storage, presentation, dismissal, cancellation-storage, error, and step-appearance configuration. Feature IDs are now stable strings.
