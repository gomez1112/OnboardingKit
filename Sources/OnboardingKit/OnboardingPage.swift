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
    public let actionButtonTitle: String?
    public let action: (() -> Void)?
    
    public init(title: String, description: String, systemImage: String) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.actionButtonTitle = nil
        self.action = nil
    }
    
    public init(title: String, description: String, image: String) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
        self.actionButtonTitle = nil
        self.action = nil
    }
    
    public init(title: String, description: String, systemImage: String, actionTitle: String, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.actionButtonTitle = actionTitle
        self.action = action
    }
    
    public static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.icon == rhs.icon &&
        lhs.actionButtonTitle == rhs.actionButtonTitle
    }
}
