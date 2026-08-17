import Foundation

/// User-facing, localizable copy used by onboarding views.
public struct OnboardingCopy: Sendable {
    public var skipButtonTitle: LocalizedStringResource
    public var nextButtonTitle: LocalizedStringResource
    public var getStartedButtonTitle: LocalizedStringResource
    public var backButtonTitle: LocalizedStringResource
    public var cancelButtonTitle: LocalizedStringResource
    public var progressFormat: LocalizedStringResource
    public var progressAccessibilityLabel: LocalizedStringResource
    public var inProgressAccessibilityValue: LocalizedStringResource

    public static let `default` = OnboardingCopy()

    public init(
        skipButtonTitle: LocalizedStringResource = .init("onboarding.skip", defaultValue: "Skip", bundle: .module),
        nextButtonTitle: LocalizedStringResource = .init("onboarding.next", defaultValue: "Next", bundle: .module),
        getStartedButtonTitle: LocalizedStringResource = .init("onboarding.get-started", defaultValue: "Get Started", bundle: .module),
        backButtonTitle: LocalizedStringResource = .init("onboarding.back", defaultValue: "Back", bundle: .module),
        cancelButtonTitle: LocalizedStringResource = .init("onboarding.cancel", defaultValue: "Cancel", bundle: .module),
        progressFormat: LocalizedStringResource = .init("onboarding.progress", defaultValue: "%1$lld of %2$lld", bundle: .module),
        progressAccessibilityLabel: LocalizedStringResource = .init("onboarding.progress-label", defaultValue: "Progress", bundle: .module),
        inProgressAccessibilityValue: LocalizedStringResource = .init("onboarding.in-progress", defaultValue: "In progress", bundle: .module)
    ) {
        self.skipButtonTitle = skipButtonTitle
        self.nextButtonTitle = nextButtonTitle
        self.getStartedButtonTitle = getStartedButtonTitle
        self.backButtonTitle = backButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.progressFormat = progressFormat
        self.progressAccessibilityLabel = progressAccessibilityLabel
        self.inProgressAccessibilityValue = inProgressAccessibilityValue
    }

    func progress(current: Int, total: Int) -> String {
        String(localized: progressFormat)
            .replacing("%1$lld", with: String(current))
            .replacing("%2$lld", with: String(total))
    }
}
