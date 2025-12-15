//
//  OnboardingAnimationConfiguration.swift
//  OnboardingKit
//
//  Created by OpenAI.
//

import SwiftUI
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Describes how onboarding animations should behave.
///
/// This configuration is intentionally small so callers can override
/// timing or transitions without switching to a different API surface.
public struct OnboardingAnimationConfiguration: Equatable, Sendable {
    /// Page transition direction used for subtle parallax and haptics.
    public enum Direction: Sendable {
        case forward
        case backward
    }

    /// Primary transition style for page changes.
    public enum TransitionStyle: Sendable, Equatable {
        /// Platform-aligned slide that feels like system onboarding.
        case platformSlide
        /// Gentle scale + fade used when movement should be minimal.
        case fade
        /// Slight zoom combined with directional offset.
        case scale
    }

    /// Transition style applied when motion is available.
    public var transitionStyle: TransitionStyle

    /// Transition style applied when reduce motion is enabled.
    public var reducedMotionTransitionStyle: TransitionStyle

    /// Duration for ease-based animations (e.g., fades).
    public var duration: TimeInterval

    /// Response value for spring-based animations.
    public var springResponse: TimeInterval

    /// Damping fraction for spring-based animations.
    public var springDampingFraction: CGFloat

    /// Whether light haptics should fire on primary interactions (iOS/tvOS only).
    public var enableHaptics: Bool

    /// Default configuration tuned to feel similar to Apple system UI.
    public static let `default` = OnboardingAnimationConfiguration()

    /// Creates a configuration with custom timings and transitions.
    public init(
        transitionStyle: TransitionStyle = .platformSlide,
        reducedMotionTransitionStyle: TransitionStyle = .fade,
        duration: TimeInterval = 0.35,
        springResponse: TimeInterval = 0.55,
        springDampingFraction: CGFloat = 0.82,
        enableHaptics: Bool = true
    ) {
        self.transitionStyle = transitionStyle
        self.reducedMotionTransitionStyle = reducedMotionTransitionStyle
        self.duration = duration
        self.springResponse = springResponse
        self.springDampingFraction = springDampingFraction
        self.enableHaptics = enableHaptics
    }

    /// The primary page animation respecting motion preferences.
    func pageAnimation(reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        return .spring(response: springResponse, dampingFraction: springDampingFraction)
    }

    /// Button or indicator animation tuned for micro interactions.
    func microInteractionAnimation(reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        return .spring(response: 0.44, dampingFraction: 0.9)
    }

    /// Fade/slide transitions used for per-platform containers.
    func transition(for direction: Direction, reduceMotion: Bool) -> AnyTransition {
        let style = reduceMotion ? reducedMotionTransitionStyle : transitionStyle
        switch style {
            case .platformSlide:
                return .move(edge: direction == .forward ? .trailing : .leading)
                    .combined(with: .opacity)
            case .fade:
                return .opacity
            case .scale:
                return .asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.98)).combined(with: .offset(x: direction == .forward ? 12 : -12)),
                    removal: .opacity
                )
        }
    }
}

// MARK: - Haptics

extension OnboardingAnimationConfiguration {
    func firePrimaryHapticIfNeeded() {
        guard enableHaptics else { return }
        #if os(iOS) || os(tvOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}
