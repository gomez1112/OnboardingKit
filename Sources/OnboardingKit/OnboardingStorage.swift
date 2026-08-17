import Foundation

enum OnboardingStorage {
    static func storeVersion(_ version: String, in defaults: UserDefaults) {
        defaults.set(version, forKey: OnboardingManager.storageKey)
    }

    static func cancel(version: String, storesVersion: Bool, in defaults: UserDefaults) {
        guard storesVersion else { return }
        storeVersion(version, in: defaults)
    }
}
