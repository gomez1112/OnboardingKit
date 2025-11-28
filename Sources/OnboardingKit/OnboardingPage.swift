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
    public let backgroundColor: Color // New Property
    public let actionButtonTitle: String?
    public let action: (() -> Void)?
    
    public init(title: String, description: String, systemImage: String, backgroundColor: Color = .clear) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.backgroundColor = backgroundColor
        self.actionButtonTitle = nil
        self.action = nil
    }
    
    public init(title: String, description: String, image: String, backgroundColor: Color = .clear) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
        self.backgroundColor = backgroundColor
        self.actionButtonTitle = nil
        self.action = nil
    }
    
    public init(title: String, description: String, systemImage: String, backgroundColor: Color = .clear, actionTitle: String, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.backgroundColor = backgroundColor
        self.actionButtonTitle = actionTitle
        self.action = action
    }
    
    public static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.icon == rhs.icon &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.actionButtonTitle == rhs.actionButtonTitle
    }
}
