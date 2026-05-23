import SwiftUI

/// User-facing copy used by onboarding views.
public struct OnboardingCopy: Sendable, Equatable {
    public var skipButtonTitle: String
    public var nextButtonTitle: String
    public var getStartedButtonTitle: String
    public var continueButtonTitle: String
    public var whatsNewHeaderTitle: String

    public static let `default` = OnboardingCopy()

    public init(
        skipButtonTitle: String = "Skip",
        nextButtonTitle: String = "Next",
        getStartedButtonTitle: String = "Get Started",
        continueButtonTitle: String = "Continue",
        whatsNewHeaderTitle: String = "What's New in"
    ) {
        self.skipButtonTitle = skipButtonTitle
        self.nextButtonTitle = nextButtonTitle
        self.getStartedButtonTitle = getStartedButtonTitle
        self.continueButtonTitle = continueButtonTitle
        self.whatsNewHeaderTitle = whatsNewHeaderTitle
    }
}
