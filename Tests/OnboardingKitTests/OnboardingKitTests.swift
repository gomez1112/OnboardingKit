import Testing
@testable import OnboardingKit

@Test func builderResolvesConditionalAndRepeatedSteps() {
    let includeFeatures = true
    let repeated = ["one", "two"]

    @OnboardingBuilder
    func makeSteps() -> [OnboardingStep] {
        OnboardingStep.welcome(
            id: "welcome",
            title: "Welcome",
            subtitle: "Hello",
            systemImage: "sparkles"
        )
        if includeFeatures {
            OnboardingStep.features(id: "features", title: "Features", features: [])
        }
        for id in repeated {
            OnboardingStep.custom(id: id, title: id)
        }
    }

    #expect(makeSteps().map(\.id) == ["welcome", "features", "one", "two"])
}

@Test(arguments: [
    ("", "1.0", OnboardingVersionDecision.firstLaunch),
    ("1.0", "2.0", OnboardingVersionDecision.whatsNew),
    ("2.0", "2.0", OnboardingVersionDecision.none)
])
func versionDecision(
    storedVersion: String,
    currentVersion: String,
    expected: OnboardingVersionDecision
) {
    #expect(
        OnboardingVersionDecision.resolve(
            storedVersion: storedVersion,
            currentVersion: currentVersion
        ) == expected
    )
}
