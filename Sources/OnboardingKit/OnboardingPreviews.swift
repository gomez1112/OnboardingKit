#if DEBUG
import SwiftUI

#Preview("Welcome") {
    OnboardingFlow { .welcome(id: "welcome", title: "Welcome", subtitle: "A guided start", systemImage: "sparkles") }
}

#Preview("Features · Dots") {
    OnboardingFlow(progressStyle: .dots) {
        .features(id: "features", title: "Highlights", features: [.init(title: "Private", systemImage: "lock")])
        .custom(id: "finish", title: "Ready")
    }
}

#Preview("Custom · Fraction") {
    OnboardingFlow(progressStyle: .fraction) { .custom(id: "profile", title: "Create a Profile") } customContent: { _ in
        TextField("Name", text: .constant(""))
            .onboardingStepComplete(false)
    }
}

#Preview("Hidden Progress · Dark") {
    OnboardingFlow(progressStyle: .hidden) { .welcome(id: "welcome", title: "Welcome", subtitle: "No progress indicator", systemImage: "moon") }
        .preferredColorScheme(.dark)
}

#Preview("Accessibility Dynamic Type") {
    OnboardingFlow { .features(id: "features", title: "Designed to Adapt", subtitle: "Larger text remains readable", features: [.init(title: "Accessible", subtitle: "Supports Dynamic Type", systemImage: "accessibility")]) }
        .dynamicTypeSize(.accessibility3)
}
#endif
