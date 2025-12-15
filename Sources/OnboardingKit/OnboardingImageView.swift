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
        switch icon {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundStyle(effectiveColor)
            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
        }
        .accessibilityLabel(accessibilityLabel ?? "")
        .accessibilityAddTraits(.isImage)
        .accessibilityHidden(accessibilityLabel == nil)
    }
}

// MARK: - Cross Platform Color Shim
// Fixes the issue where `UIColor` is not found on macOS.

#if os(macOS)
import AppKit
private typealias PlatformColor = NSColor
#else
import UIKit
private typealias PlatformColor = UIColor
#endif

extension Color {
    static var obk_secondarySystemBackground: Color {
#if os(macOS)
        Color(PlatformColor.windowBackgroundColor)
#else
        Color(PlatformColor.secondarySystemBackground)
#endif
    }
    
    static var obk_systemBackground: Color {
#if os(macOS)
        Color(PlatformColor.windowBackgroundColor)
#else
        Color(PlatformColor.systemBackground)
#endif
    }
}
