//
//  OnboardingButtonStyle.swift
//  OnboardingKit
//
//  Created by OpenAI.
//

import SwiftUI

struct OnboardingInteractiveButtonStyle: ButtonStyle {
    let animationConfiguration: OnboardingAnimationConfiguration
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(animationConfiguration.microInteractionAnimation(reduceMotion: reduceMotion), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                guard pressed else { return }
                animationConfiguration.firePrimaryHapticIfNeeded()
            }
    }
}
