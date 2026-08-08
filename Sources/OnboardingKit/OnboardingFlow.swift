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

    public static func == (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle &&
            lhs.icon == rhs.icon &&
            lhs.kind == rhs.kind &&
            lhs.features == rhs.features &&
            lhs.isRequired == rhs.isRequired &&
            lhs.secondaryActionTitle == rhs.secondaryActionTitle
    }
}

@resultBuilder
public enum OnboardingBuilder {
    public static func buildExpression(_ expression: OnboardingStep) -> [OnboardingStep] { [expression] }
    public static func buildExpression(_ expression: [OnboardingStep]) -> [OnboardingStep] { expression }
    public static func buildBlock() -> [OnboardingStep] { [] }
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
        initialStepIndex: Int = 0,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        @OnboardingBuilder steps: () -> [OnboardingStep],
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        let resolvedSteps = steps()
        self.tint = tint
        self.copy = copy
        self.progressStyle = progressStyle
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onSkip = onSkip
        self.steps = resolvedSteps
        self.customContent = customContent
        _currentIndex = State(initialValue: resolvedSteps.indices.contains(initialStepIndex) ? initialStepIndex : 0)
    }

    /// Creates a flow from an already-resolved collection of steps.
    public init(
        steps: [OnboardingStep],
        tint: Color = .blue,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        self.tint = tint
        self.copy = copy
        self.progressStyle = progressStyle
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onSkip = onSkip
        self.steps = steps
        self.customContent = customContent
        _currentIndex = State(initialValue: steps.indices.contains(initialStepIndex) ? initialStepIndex : 0)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let step = activeStep {
                Spacer(minLength: 28)

                VStack(spacing: 24) {
                    OnboardingStepHeader(step: step, tint: tint)
                    OnboardingStepBody(step: step, tint: tint, customContent: customContent)
                }
                .frame(maxWidth: 520)

                Spacer(minLength: 28)

                OnboardingStepControls(
                    step: step,
                    copy: copy,
                    progressStyle: progressStyle,
                    tint: tint,
                    isLastStep: isLastStep,
                    isPerformingAction: isPerformingAction,
                    currentIndex: currentIndex,
                    totalSteps: max(steps.count, 1),
                    onBack: { currentIndex -= 1 },
                    onCancel: onCancel,
                    onSkip: onSkip,
                    advance: { await handlePrimaryAction(step: step) }
                )
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
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

public extension OnboardingFlow where CustomStepContent == EmptyView {
    /// Creates a welcome/features flow without requiring a custom-content closure.
    init(
        tint: Color = .blue,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        @OnboardingBuilder steps: () -> [OnboardingStep]
    ) {
        self.init(
            steps: steps(),
            tint: tint,
            copy: copy,
            progressStyle: progressStyle,
            initialStepIndex: initialStepIndex,
            onComplete: onComplete,
            onCancel: onCancel,
            onSkip: onSkip,
            customContent: { _ in EmptyView() }
        )
    }

    /// Creates a flow from resolved steps without custom content.
    init(
        steps: [OnboardingStep],
        tint: Color = .blue,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil
    ) {
        self.init(
            steps: steps,
            tint: tint,
            copy: copy,
            progressStyle: progressStyle,
            initialStepIndex: initialStepIndex,
            onComplete: onComplete,
            onCancel: onCancel,
            onSkip: onSkip,
            customContent: { _ in EmptyView() }
        )
    }
}

private struct OnboardingStepHeader: View {
    let step: OnboardingStep
    let tint: Color

    var body: some View {
        VStack(spacing: 14) {
            if let icon = step.icon {
                OnboardingImageView(icon: icon, tintColor: tint, symbolColor: nil, size: 84)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)

                if let subtitle = step.subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
            VStack(alignment: .leading, spacing: 10) {
                ForEach(step.features) { feature in
                    OnboardingFeatureRow(feature: feature, tint: tint)
                }
            }
            .frame(maxWidth: 420)
        case .custom:
            customContent(step)
        }
    }
}

private struct OnboardingFeatureRow: View {
    let feature: OnboardingStep.Feature
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle = feature.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        )
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
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? tint : .secondary.opacity(0.3))
                        .frame(width: index == currentIndex ? 24 : 8, height: 8)
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
    let progressStyle: OnboardingProgressStyle
    let tint: Color
    let isLastStep: Bool
    let isPerformingAction: Bool
    let currentIndex: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onCancel: (@MainActor @Sendable () async -> Void)?
    let onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)?
    let advance: @MainActor @Sendable () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if currentIndex > 0 {
                    Button("Back") { onBack() }
                        .buttonStyle(.plain)
                        .foregroundStyle(tint)
                        .disabled(isPerformingAction)
                }

                Spacer()

                if let onCancel {
                    Button("Cancel") {
                        Task { @MainActor in await onCancel() }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(tint)
                    .disabled(isPerformingAction)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32, alignment: .center)
            .font(.body.weight(.medium))

            OnboardingProgressFooter(
                progressStyle: progressStyle,
                tint: tint,
                currentIndex: currentIndex,
                total: totalSteps
            )

            Button {
                Task { @MainActor in await advance() }
            } label: {
                HStack(spacing: 8) {
                    if isPerformingAction {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isLastStep ? copy.getStartedButtonTitle : copy.nextButtonTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
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
        .frame(maxWidth: 420)
    }
}
