//
//  OnboardingManager.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 12/14/25.
//

import Foundation

public enum OnboardingManager {
    // 1. Define the key in one place
    static let storageKey = "com.onboardingkit.lastSeenVersion"
    
    // 2. The reset function lives here now (no generic issues!)
    public static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
