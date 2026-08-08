/// User-facing copy used by onboarding views.
public struct OnboardingCopy: Sendable, Equatable {
    public var skipButtonTitle: String
    public var nextButtonTitle: String
    public var getStartedButtonTitle: String

    public static let `default` = OnboardingCopy()

    public init(
        skipButtonTitle: String = "Skip",
        nextButtonTitle: String = "Next",
        getStartedButtonTitle: String = "Get Started"
    ) {
        self.skipButtonTitle = skipButtonTitle
        self.nextButtonTitle = nextButtonTitle
        self.getStartedButtonTitle = getStartedButtonTitle
    }
}
