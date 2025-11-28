//
//  FeatureItem.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct FeatureItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let icon: OnboardingIcon
    public let backgroundColor: Color // New Property
    public let iconColor: Color?
    
    public init(title: String, description: String, systemImage: String, backgroundColor: Color = .clear, iconColor: Color? = nil) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }
    
    public init(title: String, description: String, image: String, backgroundColor: Color = .clear, iconColor: Color? = nil) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }
}
