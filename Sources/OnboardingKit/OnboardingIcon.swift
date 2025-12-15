//
//  OnboardingIcon.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

/// Icon source for onboarding content.
public enum OnboardingIcon: Equatable, Sendable {
    /// An SF Symbol identifier to render.
    case system(String)

    /// An asset catalog image name to render.
    case asset(String)
}
