import Foundation

/// Utilities for coordinating onboarding storage and resets.
public enum OnboardingManager {
    /// Shared key used to persist the most recently viewed app version.
    public static let storageKey = "com.onboardingkit.lastSeenVersion"

    /// Clears the stored onboarding version so flows show again on next launch.
    @MainActor
    public static func resetOnboarding(suiteName: String? = nil) {
        let store = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        store.removeObject(forKey: storageKey)
    }
}
