//
//  OnboardingManager.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 12/14/25.
//

import Foundation

/// Utilities for coordinating onboarding storage and resets.
public enum OnboardingManager {
    /// Shared key used to persist the most recently viewed app version.
    static let storageKey = "com.onboardingkit.lastSeenVersion"

    /// Clears the stored onboarding version so flows show again on next launch.
    public static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
