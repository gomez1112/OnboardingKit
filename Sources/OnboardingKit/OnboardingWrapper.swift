import SwiftUI

/// Presentation options for automatically configured or manually replayed flows.
/// Controls how a wrapper presents its onboarding flow.
public enum OnboardingPresentationStyle: Sendable, Equatable {
    case automatic
    case sheet
    case fullScreen
}

/// A manual request to replay one of the configured flows.
public enum OnboardingPresentation: Sendable, Equatable {
    case firstLaunch
    case whatsNew
}

private enum ActiveOnboardingFlow: Identifiable {
    case firstLaunch
    case whatsNew

    var id: String {
        switch self {
        case .firstLaunch: "firstLaunch"
        case .whatsNew: "whatsNew"
        }
    }
}

enum OnboardingVersionDecision: Sendable, Equatable {
    case firstLaunch
    case whatsNew
    case none

    static func resolve(storedVersion: String, currentVersion: String) -> Self {
        if storedVersion.isEmpty { return .firstLaunch }
        let storedComponents = storedVersion.split(separator: ".").map(String.init).dropTrailingZeroes()
        let currentComponents = currentVersion.split(separator: ".").map(String.init).dropTrailingZeroes()
        if storedComponents == currentComponents { return .none }
        if currentVersion.compare(storedVersion, options: .numeric) == .orderedDescending { return .whatsNew }
        return .none
    }
}

/// Wraps an app's root content and presents unified ``OnboardingFlow`` instances.
public struct OnboardingWrapper<Content: View, CustomStepContent: View>: View {
    @AppStorage(OnboardingManager.storageKey) private var lastSeenVersion = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var activeFlow: ActiveOnboardingFlow?

    @Binding private var presentation: OnboardingPresentation?
    private let currentVersion: String
    private let firstLaunchSteps: [OnboardingStep]
    private let whatsNewSteps: [OnboardingStep]
    private let tint: Color?
    private let progressStyle: OnboardingProgressStyle
    private let animationConfiguration: OnboardingAnimationConfiguration
    private let copy: OnboardingCopy
    private let onComplete: (@MainActor @Sendable () async -> Void)?
    private let onSkip: (@MainActor @Sendable (String) async -> Void)?
    private let onStepAppear: (@MainActor @Sendable (String) async -> Void)?
    private let onError: (@MainActor @Sendable (any Error) async -> Void)?
    private let onCancel: (@MainActor @Sendable () async -> Void)?
    private let interactiveDismissDisabled: Bool
    private let storesVersionOnCancel: Bool
    private let presentationStyle: OnboardingPresentationStyle
    private let content: Content
    private let customContent: (OnboardingStep) -> CustomStepContent

    public init(
        currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        suiteName: String? = nil,
        tint: Color? = nil,
        progressStyle: OnboardingProgressStyle = .dots,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        copy: OnboardingCopy = .default,
        presentation: Binding<OnboardingPresentation?> = .constant(nil),
        presentationStyle: OnboardingPresentationStyle = .automatic,
        interactiveDismissDisabled: Bool = true,
        storesVersionOnCancel: Bool = false,
        onComplete: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (String) async -> Void)? = nil,
        onStepAppear: (@MainActor @Sendable (String) async -> Void)? = nil,
        onError: (@MainActor @Sendable (any Error) async -> Void)? = nil,
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @OnboardingBuilder firstLaunchSteps: () -> [OnboardingStep],
        @OnboardingBuilder whatsNewSteps: () -> [OnboardingStep] = { () -> [OnboardingStep] in [] },
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        _lastSeenVersion = AppStorage(wrappedValue: "", OnboardingManager.storageKey, store: suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard)
        self.currentVersion = currentVersion
        self.tint = tint
        self.progressStyle = progressStyle
        self.animationConfiguration = animationConfiguration
        self.copy = copy
        self._presentation = presentation
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onStepAppear = onStepAppear
        self.onError = onError
        self.onCancel = onCancel
        self.presentationStyle = presentationStyle
        self.interactiveDismissDisabled = interactiveDismissDisabled
        self.storesVersionOnCancel = storesVersionOnCancel
        self.content = content()
        self.firstLaunchSteps = firstLaunchSteps()
        self.whatsNewSteps = whatsNewSteps()
        self.customContent = customContent
    }

    public var body: some View {
        content
            .task { evaluatePresentation() }
            .onChange(of: presentation) { _, requestedPresentation in
                guard let requestedPresentation else { return }
                present(requestedPresentation)
            }
            .modifier(OnboardingPresentationModifier(
                activeFlow: $activeFlow,
                style: presentationStyle,
                horizontalSizeClass: horizontalSizeClass,
                presentation: onboardingPresentation
            ))
    }

    @ViewBuilder
    private func onboardingPresentation(_ flow: ActiveOnboardingFlow) -> some View {
        OnboardingFlow(
            steps: steps(for: flow),
            tint: tint,
            copy: copy,
            progressStyle: progressStyle,
            animationConfiguration: animationConfiguration,
            onComplete: completeFlow,
            onCancel: onCancel == nil && !storesVersionOnCancel ? nil : cancelFlow,
            onSkip: onSkip,
            onStepAppear: onStepAppear,
            onError: onError,
            customContent: customContent
        )
        .interactiveDismissDisabled(interactiveDismissDisabled)
        .accessibilityIdentifier("OnboardingKit.onboarding")
#if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
#endif
    }

    @MainActor
    private func evaluatePresentation() {
        if let presentation {
            present(presentation)
            return
        }

        switch OnboardingVersionDecision.resolve(
            storedVersion: lastSeenVersion,
            currentVersion: currentVersion
        ) {
        case .firstLaunch:
            presentAutomatically(.firstLaunch)
        case .whatsNew:
            presentAutomatically(.whatsNew)
        case .none:
            activeFlow = nil
        }
    }

    @MainActor
    private func presentAutomatically(_ flow: ActiveOnboardingFlow) {
        guard !steps(for: flow).isEmpty else {
            lastSeenVersion = currentVersion
            activeFlow = nil
            return
        }
        activeFlow = flow
    }

    @MainActor
    private func present(_ requestedPresentation: OnboardingPresentation) {
        let flow: ActiveOnboardingFlow = switch requestedPresentation {
        case .firstLaunch: .firstLaunch
        case .whatsNew: .whatsNew
        }
        guard !steps(for: flow).isEmpty else {
            presentation = nil
            activeFlow = nil
            return
        }
        activeFlow = flow
    }

    private func steps(for flow: ActiveOnboardingFlow) -> [OnboardingStep] {
        switch flow {
        case .firstLaunch: firstLaunchSteps
        case .whatsNew: whatsNewSteps
        }
    }

    @MainActor
    private func completeFlow() async {
        lastSeenVersion = currentVersion
        activeFlow = nil
        presentation = nil
        await onComplete?()
    }

    @MainActor
    private func cancelFlow() async {
        if storesVersionOnCancel { lastSeenVersion = currentVersion }
        activeFlow = nil
        presentation = nil
        await onCancel?()
    }
}

private extension Array where Element == String {
    func dropTrailingZeroes() -> Self {
        var result = self
        while result.last == "0" { result.removeLast() }
        return result
    }
}

public extension OnboardingWrapper where CustomStepContent == EmptyView {
    /// Creates an automatic onboarding wrapper for flows without custom step content.
    init(
        currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        suiteName: String? = nil,
        tint: Color? = nil,
        progressStyle: OnboardingProgressStyle = .dots,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        copy: OnboardingCopy = .default,
        presentation: Binding<OnboardingPresentation?> = .constant(nil),
        presentationStyle: OnboardingPresentationStyle = .automatic,
        interactiveDismissDisabled: Bool = true,
        storesVersionOnCancel: Bool = false,
        onComplete: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (String) async -> Void)? = nil,
        onStepAppear: (@MainActor @Sendable (String) async -> Void)? = nil,
        onError: (@MainActor @Sendable (any Error) async -> Void)? = nil,
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @OnboardingBuilder firstLaunchSteps: () -> [OnboardingStep],
        @OnboardingBuilder whatsNewSteps: () -> [OnboardingStep] = { () -> [OnboardingStep] in [] }
    ) {
        self.init(
            currentVersion: currentVersion,
            suiteName: suiteName,
            tint: tint,
            progressStyle: progressStyle,
            animationConfiguration: animationConfiguration,
            copy: copy,
            presentation: presentation,
            presentationStyle: presentationStyle,
            interactiveDismissDisabled: interactiveDismissDisabled,
            storesVersionOnCancel: storesVersionOnCancel,
            onComplete: onComplete,
            onSkip: onSkip,
            onStepAppear: onStepAppear,
            onError: onError,
            onCancel: onCancel,
            content: content,
            firstLaunchSteps: firstLaunchSteps,
            whatsNewSteps: whatsNewSteps,
            customContent: { _ in EmptyView() }
        )
    }
}

private struct OnboardingPresentationModifier<Presented: View>: ViewModifier {
    @Binding var activeFlow: ActiveOnboardingFlow?
    let style: OnboardingPresentationStyle
    let horizontalSizeClass: UserInterfaceSizeClass?
    let presentation: (ActiveOnboardingFlow) -> Presented

    @ViewBuilder
    func body(content: Content) -> some View {
#if os(iOS) || os(visionOS)
        switch resolvedStyle {
        case .fullScreen:
            content.fullScreenCover(item: $activeFlow, content: presentation)
        case .sheet, .automatic:
            content.sheet(item: $activeFlow, content: presentation)
        }
#else
        content.sheet(item: $activeFlow, content: presentation)
#endif
    }

    private var resolvedStyle: OnboardingPresentationStyle {
        guard style == .automatic else { return style }
        return horizontalSizeClass == .compact ? .fullScreen : .sheet
    }
}
