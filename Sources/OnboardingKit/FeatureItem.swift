//
//  FeatureItem.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// A feature highlight that appears in the "What's New" sheet.
public struct FeatureItem: Identifiable, Equatable, Sendable {
    /// Stable identifier used by SwiftUI lists.
    public let id = UUID()

    /// Title describing the feature.
    public let title: String

    /// Supporting copy that explains the feature value.
    public let description: String

    /// Icon representation, either an asset name or SF Symbol.
    public let icon: OnboardingIcon

    /// Background color applied to the card container.
    public let backgroundColor: Color

    /// Optional override for the icon tint.
    public let iconColor: Color?

    /// Creates a feature item using an SF Symbol.
    /// - Parameters:
    ///   - title: The headline for the feature.
    ///   - description: Supporting text that describes the change.
    ///   - systemImage: The SF Symbol name to render.
    ///   - backgroundColor: Background color for the feature row.
    ///   - iconColor: Optional tint for the symbol.
    public init(title: String, description: String, systemImage: String, backgroundColor: Color = .clear, iconColor: Color? = nil) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }

    /// Creates a feature item using an asset image.
    /// - Parameters:
    ///   - title: The headline for the feature.
    ///   - description: Supporting text that describes the change.
    ///   - image: The asset name to display.
    ///   - backgroundColor: Background color for the feature row.
    ///   - iconColor: Optional tint for the asset.
    public init(title: String, description: String, image: String, backgroundColor: Color = .clear, iconColor: Color? = nil) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }
}
