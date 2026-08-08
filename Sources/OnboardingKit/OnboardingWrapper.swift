import SwiftUI

/// Presentation options for automatically configured or manually replayed flows.
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
        if storedVersion != currentVersion { return .whatsNew }
        return .none
    }
}

/// Wraps an app's root content and presents unified ``OnboardingFlow`` instances.
public struct OnboardingWrapper<Content: View, CustomStepContent: View>: View {
    @AppStorage(OnboardingManager.storageKey) private var lastSeenVersion = ""
    @State private var activeFlow: ActiveOnboardingFlow?

    @Binding private var presentation: OnboardingPresentation?
    private let appName: String
    private let currentVersion: String
    private let firstLaunchSteps: [OnboardingStep]
    private let whatsNewSteps: [OnboardingStep]
    private let tint: Color
    private let progressStyle: OnboardingProgressStyle
    private let animationConfiguration: OnboardingAnimationConfiguration
    private let copy: OnboardingCopy
    private let onComplete: (@MainActor @Sendable () async -> Void)?
    private let onSkip: (@MainActor @Sendable (String) async -> Void)?
    private let onCancel: (@MainActor @Sendable () async -> Void)?
    private let content: Content
    private let customContent: (OnboardingStep) -> CustomStepContent

    public init(
        appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App",
        currentVersion: String,
        tint: Color = .blue,
        progressStyle: OnboardingProgressStyle = .dots,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        copy: OnboardingCopy = .default,
        presentation: Binding<OnboardingPresentation?> = .constant(nil),
        onComplete: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (String) async -> Void)? = nil,
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @OnboardingBuilder firstLaunchSteps: () -> [OnboardingStep],
        @OnboardingBuilder whatsNewSteps: () -> [OnboardingStep] = { () -> [OnboardingStep] in [] },
        @ViewBuilder customContent: @escaping (OnboardingStep) -> CustomStepContent
    ) {
        self.appName = appName
        self.currentVersion = currentVersion
        self.tint = tint
        self.progressStyle = progressStyle
        self.animationConfiguration = animationConfiguration
        self.copy = copy
        self._presentation = presentation
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onCancel = onCancel
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
#if os(iOS)
            .fullScreenCover(item: $activeFlow, content: onboardingPresentation)
#else
            .sheet(item: $activeFlow, content: onboardingPresentation)
#endif
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
            onCancel: onCancel == nil ? nil : cancelFlow,
            onSkip: onSkip,
            customContent: customContent
        )
        .interactiveDismissDisabled()
        .accessibilityIdentifier("\(appName).onboarding")
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
        activeFlow = nil
        presentation = nil
        await onCancel?()
    }
}

public extension OnboardingWrapper where CustomStepContent == EmptyView {
    /// Creates an automatic onboarding wrapper for flows without custom step content.
    init(
        appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App",
        currentVersion: String,
        tint: Color = .blue,
        progressStyle: OnboardingProgressStyle = .dots,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        copy: OnboardingCopy = .default,
        presentation: Binding<OnboardingPresentation?> = .constant(nil),
        onComplete: (@MainActor @Sendable () async -> Void)? = nil,
        onSkip: (@MainActor @Sendable (String) async -> Void)? = nil,
        onCancel: (@MainActor @Sendable () async -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @OnboardingBuilder firstLaunchSteps: () -> [OnboardingStep],
        @OnboardingBuilder whatsNewSteps: () -> [OnboardingStep] = { () -> [OnboardingStep] in [] }
    ) {
        self.init(
            appName: appName,
            currentVersion: currentVersion,
            tint: tint,
            progressStyle: progressStyle,
            animationConfiguration: animationConfiguration,
            copy: copy,
            presentation: presentation,
            onComplete: onComplete,
            onSkip: onSkip,
            onCancel: onCancel,
            content: content,
            firstLaunchSteps: firstLaunchSteps,
            whatsNewSteps: whatsNewSteps,
            customContent: { _ in EmptyView() }
        )
    }
}
