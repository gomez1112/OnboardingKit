import Foundation
import SwiftUI

/// The visual treatment used to communicate progress through a flow.
public enum OnboardingProgressStyle: Sendable, Equatable {
    case dots
    case fraction
    case hidden
}

/// A declarative unit of onboarding content and behavior.
public struct OnboardingStep: Identifiable, Sendable, Equatable {
    /// A stable feature row displayed by a feature step.
    public struct Feature: Identifiable, Sendable, Equatable {
        private let explicitID: String?
        public let title: LocalizedStringResource
        public let subtitle: LocalizedStringResource?
        public let systemImage: String

        public var id: String {
            explicitID ?? "\(String(localized: title))|\(subtitle.map { String(localized: $0) } ?? "")|\(systemImage)"
        }

        public init(id: String? = nil, title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil, systemImage: String) {
            explicitID = id
            self.title = title
            self.subtitle = subtitle
            self.systemImage = systemImage
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            String(localized: lhs.title) == String(localized: rhs.title) &&
                lhs.subtitle.map { String(localized: $0) } == rhs.subtitle.map { String(localized: $0) } &&
                lhs.systemImage == rhs.systemImage
        }
    }

    /// The built-in presentation kind for a step.
    public enum Kind: Sendable, Equatable {
        case welcome
        case features
        case custom
    }

    public let id: String
    public let title: LocalizedStringResource
    public let subtitle: LocalizedStringResource?
    public let icon: OnboardingIcon?
    public let kind: Kind
    public let features: [Feature]
    public let isRequired: Bool
    public let beforeAdvance: (@MainActor @Sendable () async throws -> Void)?
    public let secondaryActionTitle: LocalizedStringResource?
    public let secondaryAction: (@MainActor @Sendable () async -> Void)?

    public static func welcome(id: String, title: LocalizedStringResource, subtitle: LocalizedStringResource, systemImage: String) -> Self {
        .init(id: id, title: title, subtitle: subtitle, icon: .system(systemImage), kind: .welcome)
    }

    public static func features(id: String, title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil, features: [Feature]) -> Self {
        .init(id: id, title: title, subtitle: subtitle, icon: nil, kind: .features, features: features)
    }

    public static func custom(
        id: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        systemImage: String? = nil,
        image: String? = nil,
        isRequired: Bool = true,
        beforeAdvance: (@MainActor @Sendable () async throws -> Void)? = nil,
        secondaryActionTitle: LocalizedStringResource? = nil,
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
            beforeAdvance: beforeAdvance,
            secondaryActionTitle: secondaryActionTitle,
            secondaryAction: secondaryAction
        )
    }

    public init(
        id: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        icon: OnboardingIcon? = nil,
        kind: Kind,
        features: [Feature] = [],
        isRequired: Bool = true,
        beforeAdvance: (@MainActor @Sendable () async throws -> Void)? = nil,
        secondaryActionTitle: LocalizedStringResource? = nil,
        secondaryAction: (@MainActor @Sendable () async -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.kind = kind
        self.features = features
        self.isRequired = isRequired
        self.beforeAdvance = beforeAdvance
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }

    public static func == (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.id == rhs.id &&
            String(localized: lhs.title) == String(localized: rhs.title) &&
            lhs.subtitle.map { String(localized: $0) } == rhs.subtitle.map { String(localized: $0) } &&
            lhs.icon == rhs.icon &&
            lhs.kind == rhs.kind &&
            lhs.features == rhs.features &&
            lhs.isRequired == rhs.isRequired &&
            lhs.secondaryActionTitle.map { String(localized: $0) } == rhs.secondaryActionTitle.map { String(localized: $0) }
    }
}

/// Builds arrays of onboarding steps with Swift control flow.
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

/// Renders and coordinates a sequence of onboarding steps.
public struct OnboardingFlow<CustomStepContent: View>: View {
    private let explicitTint: Color?
    private let copy: OnboardingCopy
    private let progressStyle: OnboardingProgressStyle
    private let animationConfiguration: OnboardingAnimationConfiguration
    private let onCancel: (@MainActor @Sendable () async -> Void)?
    @State private var isStepComplete = true
    private let customContent: (OnboardingStep) -> CustomStepContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.tint) private var environmentTint
    @State private var model: OnboardingFlowModel
    @AccessibilityFocusState private var focusedStepID: String?

    public init(
        tint: Color? = nil,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onStepAppear: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onError: (@MainActor @Sendable (any Error) async -> Void)? = nil,
        @OnboardingBuilder steps: () -> [OnboardingStep],
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        let resolvedSteps = steps()
        Self.assertUniqueIDs(resolvedSteps)
        explicitTint = tint
        self.copy = copy
        self.progressStyle = progressStyle
        self.animationConfiguration = animationConfiguration
        self.onCancel = onCancel
        self.customContent = customContent
        _model = State(initialValue: OnboardingFlowModel(
            steps: resolvedSteps,
            initialStepIndex: initialStepIndex,
            onComplete: onComplete,
            onSkip: onSkip,
            onStepAppear: onStepAppear,
            onError: onError
        ))
    }

    /// Creates a flow from an already-resolved collection of steps.
    public init(
        steps: [OnboardingStep],
        tint: Color? = nil,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onStepAppear: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onError: (@MainActor @Sendable (any Error) async -> Void)? = nil,
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        Self.assertUniqueIDs(steps)
        explicitTint = tint
        self.copy = copy
        self.progressStyle = progressStyle
        self.animationConfiguration = animationConfiguration
        self.onCancel = onCancel
        self.customContent = customContent
        _model = State(initialValue: OnboardingFlowModel(
            steps: steps,
            initialStepIndex: initialStepIndex,
            onComplete: onComplete,
            onSkip: onSkip,
            onStepAppear: onStepAppear,
            onError: onError
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let step = model.activeStep {
                Spacer(minLength: 28)

                VStack(spacing: 24) {
                    OnboardingStepHeader(step: step, tint: tint, focusedStepID: $focusedStepID)
                OnboardingStepBody(step: step, tint: tint, customContent: customContent)
                    .onPreferenceChange(OnboardingStepCompletionPreferenceKey.self) { isStepComplete = $0 }
                }
                .frame(maxWidth: 520)
                .id(step.id)
                .transition(activeStepTransition)

                Spacer(minLength: 28)

                OnboardingStepControls(
                    step: step,
                    copy: copy,
                    progressStyle: progressStyle,
                    tint: tint,
                    isLastStep: model.isLastStep,
                    isPerformingAction: model.isPerformingAction,
                    currentIndex: model.currentIndex,
                    totalSteps: max(model.steps.count, 1),
                    progressAnimation: progressAnimation,
                    isStepComplete: isStepComplete,
                    onBack: { withAnimation(animationConfiguration.animation) { model.goBack() } },
                    onCancel: onCancel,
                    skip: { await model.skip() },
                    advance: { await model.handlePrimaryAction(step: step) }
                )
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .task(id: model.currentIndex) {
            focusedStepID = model.activeStep?.id
            await model.reportStepAppearance()
        }
        .onChange(of: model.currentIndex) { _, _ in isStepComplete = true }
    }

    private var tint: Color { explicitTint ?? environmentTint ?? .accentColor }

    private var activeStepTransition: AnyTransition {
        if reduceMotion {
            return animationConfiguration.reduceMotionTransition
        }

        switch model.navigationDirection {
        case .forward:
            return animationConfiguration.forwardTransition
        case .backward:
            return animationConfiguration.backwardTransition
        }
    }

    private var progressAnimation: Animation? {
        animationConfiguration.animatesProgress ? animationConfiguration.animation : nil
    }

    private static func assertUniqueIDs(_ steps: [OnboardingStep]) {
#if DEBUG
        var seen = Set<String>()
        for step in steps where !seen.insert(step.id).inserted {
            assertionFailure("Duplicate onboarding step ID: \(step.id)")
        }
#endif
    }

}

public extension OnboardingFlow where CustomStepContent == EmptyView {
    /// Creates a welcome/features flow without requiring a custom-content closure.
    init(
        tint: Color? = nil,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onStepAppear: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onError: (@MainActor @Sendable (any Error) async -> Void)? = nil,
        @OnboardingBuilder steps: () -> [OnboardingStep]
    ) {
        self.init(
            steps: steps(),
            tint: tint,
            copy: copy,
            progressStyle: progressStyle,
            initialStepIndex: initialStepIndex,
            animationConfiguration: animationConfiguration,
            onComplete: onComplete,
            onCancel: onCancel,
            onSkip: onSkip,
            onStepAppear: onStepAppear,
            onError: onError,
            customContent: { _ in EmptyView() }
        )
    }

    /// Creates a flow from resolved steps without custom content.
    init(
        steps: [OnboardingStep],
        tint: Color? = nil,
        copy: OnboardingCopy = .default,
        progressStyle: OnboardingProgressStyle = .dots,
        initialStepIndex: Int = 0,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        onComplete: @escaping @MainActor @Sendable () async -> Void = {},
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onStepAppear: (@MainActor @Sendable (_ stepID: String) async -> Void)? = nil,
        onError: (@MainActor @Sendable (any Error) async -> Void)? = nil
    ) {
        self.init(
            steps: steps,
            tint: tint,
            copy: copy,
            progressStyle: progressStyle,
            initialStepIndex: initialStepIndex,
            animationConfiguration: animationConfiguration,
            onComplete: onComplete,
            onCancel: onCancel,
            onSkip: onSkip,
            onStepAppear: onStepAppear,
            onError: onError,
            customContent: { _ in EmptyView() }
        )
    }
}

private struct OnboardingStepHeader: View {
    let step: OnboardingStep
    let tint: Color
    var focusedStepID: AccessibilityFocusState<String?>.Binding

    var body: some View {
        VStack(spacing: 14) {
            if let icon = step.icon {
                OnboardingImageView(icon: icon, tintColor: tint, symbolColor: nil, size: 84)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused(focusedStepID, equals: step.id)

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
    let copy: OnboardingCopy

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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(copy.progressAccessibilityLabel))
            .accessibilityValue(Text(copy.progress(current: currentIndex + 1, total: total)))
        case .fraction:
            Text(copy.progress(current: currentIndex + 1, total: total))
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
    let progressAnimation: Animation?
    let isStepComplete: Bool
    let onBack: () -> Void
    let onCancel: (@MainActor @Sendable () async -> Void)?
    let skip: @MainActor @Sendable () async -> Void
    let advance: @MainActor @Sendable () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if currentIndex > 0 {
                    Button(copy.backButtonTitle) { onBack() }
                        .buttonStyle(.borderless)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                        .foregroundStyle(tint)
                        .disabled(isPerformingAction)
                }

                Spacer()

                if let onCancel {
                    Button(copy.cancelButtonTitle) {
                        Task { @MainActor in await onCancel() }
                    }
                    .buttonStyle(.borderless)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
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
                total: totalSteps,
                copy: copy
            )
            .animation(progressAnimation, value: currentIndex)

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
            .accessibilityValue(isPerformingAction ? Text(copy.inProgressAccessibilityValue) : Text(""))
            .disabled(isPerformingAction || !isStepComplete)

            if !step.isRequired {
                Button(copy.skipButtonTitle) {
                    Task { @MainActor in
                        await skip()
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

struct OnboardingStepCompletionPreferenceKey: PreferenceKey {
    static let defaultValue = true
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value && nextValue() }
}

public extension View {
    /// Reports whether this custom step's requirements are satisfied.
    func onboardingStepComplete(_ isComplete: Bool) -> some View {
        preference(key: OnboardingStepCompletionPreferenceKey.self, value: isComplete)
    }
}
