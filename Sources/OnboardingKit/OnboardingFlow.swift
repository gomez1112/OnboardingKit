import SwiftUI

public enum OnboardingProgressStyle: Sendable, Equatable {
    case dots
    case fraction
    case hidden
}

public struct OnboardingStep: Identifiable, Sendable, Equatable {
    public struct Feature: Identifiable, Sendable, Equatable {
        public let id = UUID()
        public let title: String
        public let subtitle: String?
        public let systemImage: String

        public init(title: String, subtitle: String? = nil, systemImage: String) {
            self.title = title
            self.subtitle = subtitle
            self.systemImage = systemImage
        }
    }

    public enum Kind: Sendable, Equatable {
        case welcome
        case features
        case custom
    }

    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: OnboardingIcon?
    public let kind: Kind
    public let features: [Feature]
    public let isRequired: Bool
    public let isComplete: (@MainActor @Sendable () -> Bool)?
    public let beforeAdvance: (@MainActor @Sendable () async -> Void)?
    public let secondaryActionTitle: String?
    public let secondaryAction: (@MainActor @Sendable () async -> Void)?

    public static func welcome(id: String, title: String, subtitle: String, systemImage: String) -> Self {
        .init(id: id, title: title, subtitle: subtitle, icon: .system(systemImage), kind: .welcome)
    }

    public static func features(id: String, title: String, subtitle: String? = nil, features: [Feature]) -> Self {
        .init(id: id, title: title, subtitle: subtitle, icon: nil, kind: .features, features: features)
    }

    public static func custom(
        id: String,
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        image: String? = nil,
        isRequired: Bool = true,
        isComplete: (@MainActor @Sendable () -> Bool)? = nil,
        beforeAdvance: (@MainActor @Sendable () async -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (@MainActor @Sendable () async -> Void)? = nil
    ) -> Self {
        let icon: OnboardingIcon?
        if let systemImage {
            icon = .system(systemImage)
        } else if let image {
            icon = .asset(image)
        } else {
            icon = nil
        }
        return .init(
            id: id,
            title: title,
            subtitle: subtitle,
            icon: icon,
            kind: .custom,
            isRequired: isRequired,
            isComplete: isComplete,
            beforeAdvance: beforeAdvance,
            secondaryActionTitle: secondaryActionTitle,
            secondaryAction: secondaryAction
        )
    }

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: OnboardingIcon? = nil,
        kind: Kind,
        features: [Feature] = [],
        isRequired: Bool = true,
        isComplete: (@MainActor @Sendable () -> Bool)? = nil,
        beforeAdvance: (@MainActor @Sendable () async -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (@MainActor @Sendable () async -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.kind = kind
        self.features = features
        self.isRequired = isRequired
        self.isComplete = isComplete
        self.beforeAdvance = beforeAdvance
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }
}

@resultBuilder
public enum OnboardingBuilder {
    public static func buildExpression(_ expression: OnboardingStep) -> [OnboardingStep] { [expression] }
    public static func buildBlock(_ components: [OnboardingStep]...) -> [OnboardingStep] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [OnboardingStep]?) -> [OnboardingStep] { component ?? [] }
    public static func buildEither(first component: [OnboardingStep]) -> [OnboardingStep] { component }
    public static func buildEither(second component: [OnboardingStep]) -> [OnboardingStep] { component }
    public static func buildArray(_ components: [[OnboardingStep]]) -> [OnboardingStep] { components.flatMap { $0 } }
}

public struct OnboardingFlow<CustomStepContent: View>: View {
    private let tint: Color
    private let copy: OnboardingCopy
    private let progressStyle: OnboardingProgressStyle
    private let steps: [OnboardingStep]
    private let onComplete: @MainActor @Sendable () async -> Void
    private let onCancel: (@MainActor @Sendable () async -> Void)?
    private let onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)?
    private let customContent: (OnboardingStep) -> CustomStepContent

    @State private var currentIndex = 0
    @State private var isPerformingAction = false

    public init(
        tint: Color = .blue,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        onComplete: @escaping @MainActor @Sendable () async -> Void,
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        @OnboardingBuilder steps: () -> [OnboardingStep],
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        self.tint = tint
        self.copy = copy
        self.progressStyle = progressStyle
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onSkip = onSkip
        self.steps = steps()
        self.customContent = customContent
    }

    public var body: some View {
        VStack {
            if let step = activeStep {
                OnboardingStepHeader(step: step, tint: tint)
                OnboardingStepBody(step: step, tint: tint, customContent: customContent)
                Spacer()
                OnboardingProgressFooter(progressStyle: progressStyle, tint: tint, currentIndex: currentIndex, total: max(steps.count, 1))
                OnboardingStepControls(step: step, copy: copy, tint: tint, isLastStep: isLastStep, isPerformingAction: isPerformingAction, currentIndex: currentIndex, onBack: { currentIndex -= 1 }, onCancel: onCancel, onSkip: onSkip, advance: { await handlePrimaryAction(step: step) })
            } else {
                ProgressView()
            }
        }
        .padding()
    }

    private var activeStep: OnboardingStep? {
        guard steps.indices.contains(currentIndex) else { return nil }
        return steps[currentIndex]
    }

    private var isLastStep: Bool {
        currentIndex == steps.count - 1
    }

    @MainActor
    private func handlePrimaryAction(step: OnboardingStep) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        if let beforeAdvance = step.beforeAdvance {
            await beforeAdvance()
        }
        if isLastStep {
            await onComplete()
        } else {
            currentIndex += 1
        }
        isPerformingAction = false
    }
}

private struct OnboardingStepHeader: View {
    let step: OnboardingStep
    let tint: Color

    var body: some View {
        VStack {
            if let icon = step.icon {
                OnboardingImageView(icon: icon, tintColor: tint, symbolColor: nil)
                    .accessibilityHidden(true)
            }
            Text(step.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            if let subtitle = step.subtitle {
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct OnboardingStepBody<CustomStepContent: View>: View {
    let step: OnboardingStep
    let tint: Color
    let customContent: (OnboardingStep) -> CustomStepContent

    var body: some View {
        switch step.kind {
        case .welcome:
            EmptyView()
        case .features:
            VStack(alignment: .leading) {
                ForEach(step.features) { feature in
                    Label {
                        VStack(alignment: .leading) {
                            Text(feature.title)
                            if let subtitle = feature.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: feature.systemImage)
                            .foregroundStyle(tint)
                    }
                }
            }
        case .custom:
            customContent(step)
        }
    }
}

private struct OnboardingProgressFooter: View {
    let progressStyle: OnboardingProgressStyle
    let tint: Color
    let currentIndex: Int
    let total: Int

    var body: some View {
        switch progressStyle {
        case .dots:
            HStack {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? tint : .secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
            }
        case .fraction:
            Text("\(currentIndex + 1) of \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .hidden:
            EmptyView()
        }
    }
}

private struct OnboardingStepControls: View {
    let step: OnboardingStep
    let copy: OnboardingCopy
    let tint: Color
    let isLastStep: Bool
    let isPerformingAction: Bool
    let currentIndex: Int
    let onBack: () -> Void
    let onCancel: (@MainActor @Sendable () async -> Void)?
    let onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)?
    let advance: @MainActor @Sendable () async -> Void

    var body: some View {
        VStack {
            HStack {
                if currentIndex > 0 {
                    Button("Back") { onBack() }
                        .disabled(isPerformingAction)
                }
                Spacer()
                if let onCancel {
                    Button("Cancel") {
                        Task { @MainActor in await onCancel() }
                    }
                    .disabled(isPerformingAction)
                }
            }
            Button(isLastStep ? copy.getStartedButtonTitle : copy.nextButtonTitle) {
                Task { @MainActor in await advance() }
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .disabled(isPerformingAction || !(step.isComplete?() ?? true))

            if !step.isRequired {
                Button(copy.skipButtonTitle) {
                    Task { @MainActor in
                        await onSkip?(step.id)
                        await advance()
                    }
                }
                .disabled(isPerformingAction)
            }

            if let secondaryTitle = step.secondaryActionTitle,
               let secondaryAction = step.secondaryAction {
                Button(secondaryTitle) {
                    Task { @MainActor in await secondaryAction() }
                }
                .disabled(isPerformingAction)
            }
        }
    }
}
