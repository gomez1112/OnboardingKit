//
//  FeatureItem.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import Foundation

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
