import Foundation
import Testing
@testable import OnboardingKit

@Test(arguments: [
    ("", "1.0", OnboardingVersionDecision.firstLaunch),
    ("1.9", "1.10", OnboardingVersionDecision.whatsNew),
    ("2.0", "2.0", OnboardingVersionDecision.none),
    ("2.0.0", "2.0", OnboardingVersionDecision.none),
    ("3.0", "2.0", OnboardingVersionDecision.none)
])
func versionDecision(stored: String, current: String, expected: OnboardingVersionDecision) {
    #expect(OnboardingVersionDecision.resolve(storedVersion: stored, currentVersion: current) == expected)
}

@Test @MainActor func managerResetsInjectedSuite() throws {
    let suite = "OnboardingKitTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("2.0", forKey: OnboardingManager.storageKey)
    OnboardingManager.resetOnboarding(suiteName: suite)
    #expect(defaults.string(forKey: OnboardingManager.storageKey) == nil)
}

@Test func completionAndCancelStoragePolicies() throws {
    let suite = "OnboardingKitTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    OnboardingStorage.storeVersion("2.0", in: defaults)
    #expect(defaults.string(forKey: OnboardingManager.storageKey) == "2.0")
    defaults.removeObject(forKey: OnboardingManager.storageKey)
    OnboardingStorage.cancel(version: "2.0", storesVersion: false, in: defaults)
    #expect(defaults.string(forKey: OnboardingManager.storageKey) == nil)
    OnboardingStorage.cancel(version: "2.0", storesVersion: true, in: defaults)
    #expect(defaults.string(forKey: OnboardingManager.storageKey) == "2.0")
}
