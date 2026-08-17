import Foundation
import Testing
@testable import OnboardingKit

@Test func builderSupportsControlFlow() {
    @OnboardingBuilder func steps() -> [OnboardingStep] {
        OnboardingStep.welcome(id: "welcome", title: "Welcome", subtitle: "Hello", systemImage: "sparkles")
        for id in ["one", "two"] { OnboardingStep.custom(id: id, title: LocalizedStringResource(stringLiteral: id)) }
    }
    #expect(steps().map(\.id) == ["welcome", "one", "two"])
}

@Test func featureIdentityIsStableAndEqualityUsesContent() {
    let first = OnboardingStep.Feature(title: "Fast", subtitle: "Very fast", systemImage: "bolt")
    let second = OnboardingStep.Feature(title: "Fast", subtitle: "Very fast", systemImage: "bolt")
    let explicit = OnboardingStep.Feature(id: "speed", title: "Fast", subtitle: "Very fast", systemImage: "bolt")
    #expect(first == second)
    #expect(first == explicit)
    #expect(first.id == second.id)
    #expect(explicit.id == "speed")
}
