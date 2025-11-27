//
//  OnboardingPage.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct OnboardingPage: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let icon: OnboardingIcon
    
    // HIG: "Integrate the permission request into your onboarding flow"
    // If these are set, the main button becomes an action button (e.g., "Allow Location")
    public let actionButtonTitle: String?
    public let action: (() -> Void)?
    
    /// Standard Page
    public init(title: String, description: String, systemImage: String) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.actionButtonTitle = nil
        self.action = nil
    }
    
    /// Standard Page with Asset Image
    public init(title: String, description: String, image: String) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
        self.actionButtonTitle = nil
        self.action = nil
    }
    
    /// Actionable Page (e.g., for Permissions)
    public init(title: String, description: String, systemImage: String, actionTitle: String, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.actionButtonTitle = actionTitle
        self.action = action
    }
    // MARK: - Manual Equatable Conformance
    // We must manually implement this because 'action' (a closure) cannot be compared automatically.
    public static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.icon == rhs.icon &&
        lhs.actionButtonTitle == rhs.actionButtonTitle
    }
}

public struct FeatureItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let icon: OnboardingIcon
    
    public init(title: String, description: String, systemImage: String) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
    }
    
    public init(title: String, description: String, image: String) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
    }
}
