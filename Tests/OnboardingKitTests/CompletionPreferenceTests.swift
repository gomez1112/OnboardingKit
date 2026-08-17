import Testing
@testable import OnboardingKit

@Test func completionPreferenceDefaultsToComplete() {
    #expect(OnboardingStepCompletionPreferenceKey.defaultValue)
}

@Test func completionPreferenceCombinesRequirements() {
    var value = true
    OnboardingStepCompletionPreferenceKey.reduce(value: &value) { false }
    OnboardingStepCompletionPreferenceKey.reduce(value: &value) { true }
    #expect(value == false)
}
