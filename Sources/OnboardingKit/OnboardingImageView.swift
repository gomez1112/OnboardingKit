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
    let size: CGFloat
    
    var body: some View {
        switch icon {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundStyle(tintColor)
            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
        }
    }
}
// Helper to make Color(uiColor) work on macOS
#if os(macOS)
extension Color {
    static let secondarySystemBackground = Color(NSColor.windowBackgroundColor)
    static let systemBackground = Color(NSColor.windowBackgroundColor)
}
extension UIColor {
    static let systemBackground = NSColor.windowBackgroundColor
    static let secondarySystemBackground = NSColor.windowBackgroundColor
}
#endif
