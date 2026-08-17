//
//  OnboardingImageView.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

struct OnboardingImageView: View {
    let icon: OnboardingIcon
    let tintColor: Color
    let symbolColor: Color?
    let size: CGFloat
    let accessibilityLabel: String?

    init(
        icon: OnboardingIcon,
        tintColor: Color,
        symbolColor: Color? = nil,
        size: CGFloat,
        accessibilityLabel: String? = nil
    ) {
        self.icon = icon
        self.tintColor = tintColor
        self.symbolColor = symbolColor
        self.size = size
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        let effectiveColor = symbolColor ?? tintColor
        Group {
            switch icon {
            case .system(let name):
                Image(systemName: name)
                    .font(.system(size: size))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(effectiveColor)
            case .asset(let name, let bundleIdentifier):
                Image(name, bundle: bundleIdentifier.flatMap(Bundle.init(identifier:)))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }
        }
        .modifier(AccessibilityImageModifiers(accessibilityLabel: accessibilityLabel))
    }
}

private struct AccessibilityImageModifiers: ViewModifier {
    let accessibilityLabel: String?

    func body(content: Content) -> some View {
        accessibleContent(for: content)
    }

    @ViewBuilder
    private func accessibleContent(for content: Content) -> some View {
        if let accessibilityLabel, !accessibilityLabel.isEmpty {
            content
                .accessibilityLabel(Text(accessibilityLabel))
                .accessibilityHidden(false)
        } else {
            content.accessibilityHidden(true)
        }
    }
}
