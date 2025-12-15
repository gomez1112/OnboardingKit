//
//  OnboardingPage.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// A single page within the first-launch onboarding flow.
public struct OnboardingPage: Identifiable, Equatable, Sendable {
    /// Stable identifier used by SwiftUI paging containers.
    public let id = UUID()

    /// Page title rendered prominently in the layout.
    public let title: String

    /// Supporting copy that explains the benefit.
    public let description: String

    /// Visual representation for the page.
    public let icon: OnboardingIcon

    /// Background color covering the entire page.
    public let backgroundColor: Color

    /// Optional override for the icon tint color.
    public let iconColor: Color?

    /// Optional button title displayed below the page indicators.
    public let actionButtonTitle: String?

    /// Optional action invoked when the button is tapped.
    /// Actions in UI models should generally be Sendable.
    public let action: (@Sendable () -> Void)?

    /// Creates a page using an SF Symbol.
    /// - Parameters:
    ///   - title: Title shown on the page.
    ///   - description: Supporting copy.
    ///   - systemImage: The SF Symbol name to render.
    ///   - backgroundColor: Background color for the page.
    ///   - iconColor: Optional tint for the symbol.
    public init(
        title: String,
        description: String,
        systemImage: String,
        backgroundColor: Color = .clear,
        iconColor: Color? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.actionButtonTitle = nil
        self.action = nil
    }

    /// Creates a page using an asset image.
    /// - Parameters:
    ///   - title: Title shown on the page.
    ///   - description: Supporting copy.
    ///   - image: The asset name to render.
    ///   - backgroundColor: Background color for the page.
    ///   - iconColor: Optional tint for the asset.
    public init(
        title: String,
        description: String,
        image: String,
        backgroundColor: Color = .clear,
        iconColor: Color? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = .asset(image)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.actionButtonTitle = nil
        self.action = nil
    }

    /// Creates a page that executes an action when the primary button is tapped.
    /// - Parameters:
    ///   - title: Title shown on the page.
    ///   - description: Supporting copy.
    ///   - systemImage: The SF Symbol name to render.
    ///   - backgroundColor: Background color for the page.
    ///   - iconColor: Optional tint for the symbol.
    ///   - actionTitle: Title for the actionable button.
    ///   - action: Closure executed when the button is selected.
    public init(
        title: String,
        description: String,
        systemImage: String,
        backgroundColor: Color = .clear,
        iconColor: Color? = nil,
        actionTitle: String,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = .system(systemImage)
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.actionButtonTitle = actionTitle
        self.action = action
    }

    /// Equality check that ignores non-rendered properties such as the action closure.
    public static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.icon == rhs.icon &&
            lhs.backgroundColor == rhs.backgroundColor &&
            lhs.actionButtonTitle == rhs.actionButtonTitle
    }
}
