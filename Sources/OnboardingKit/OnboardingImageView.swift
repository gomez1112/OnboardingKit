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

        // Build the base image without styling so both branches share the same shape
        let baseImage: some View = {
            switch icon {
            case .system(let name):
                return Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            case .asset(let name):
                return Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }
        }()

        // Apply styling conditionally outside the switch to keep return types aligned
        let styledImage = baseImage
            .ifCase(icon, matches: { if case .system = $0 { return true } else { return false } }) { view in
                view.foregroundStyle(effectiveColor)
            }

        return styledImage
            .modifier(AccessibilityImageModifiers(accessibilityLabel: accessibilityLabel))
    }
}

private struct AccessibilityImageModifiers: ViewModifier {
    let accessibilityLabel: String?

    func body(content: Content) -> some View {
        var view = AnyView(content)

        if let label = accessibilityLabel, !label.isEmpty {
            view = AnyView(view.accessibilityLabel(Text(label)))
        }

        // Hide from accessibility if there's no useful label
        view = AnyView(view.accessibilityHidden(accessibilityLabel == nil || accessibilityLabel?.isEmpty == true))

        // Add image trait where supported (iOS, tvOS, watchOS). Not available on macOS.
        #if os(iOS) || os(tvOS) || os(watchOS)
        view = AnyView(view.accessibilityAddTraits(.isImage))
        #endif

        return view
    }
}

// MARK: - View Conditional Modifier Helpers
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifCase<T>(_ value: T, matches: (T) -> Bool, transform: (Self) -> some View) -> some View {
        if matches(value) {
            transform(self)
        } else {
            self
        }
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

