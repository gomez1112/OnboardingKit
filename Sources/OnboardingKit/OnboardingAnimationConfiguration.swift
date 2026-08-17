import SwiftUI

/// Animations and transitions used while navigating between steps.
public struct OnboardingAnimationConfiguration {
    public var animation: Animation
    public var forwardTransition: AnyTransition
    public var backwardTransition: AnyTransition
    public var reduceMotionTransition: AnyTransition
    public var animatesProgress: Bool

    public init(
        animation: Animation,
        forwardTransition: AnyTransition,
        backwardTransition: AnyTransition,
        reduceMotionTransition: AnyTransition,
        animatesProgress: Bool
    ) {
        self.animation = animation
        self.forwardTransition = forwardTransition
        self.backwardTransition = backwardTransition
        self.reduceMotionTransition = reduceMotionTransition
        self.animatesProgress = animatesProgress
    }

    public static var `default`: OnboardingAnimationConfiguration {
        OnboardingAnimationConfiguration(
            animation: .snappy,
            forwardTransition: .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ),
            backwardTransition: .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            ),
            reduceMotionTransition: .opacity,
            animatesProgress: true
        )
    }
}
