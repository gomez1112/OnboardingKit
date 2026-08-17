import Observation

enum NavigationDirection {
    case forward
    case backward
}

@MainActor
@Observable
final class OnboardingFlowModel {
    private(set) var currentIndex: Int
    private(set) var navigationDirection: NavigationDirection = .forward
    private(set) var isPerformingAction = false
    let steps: [OnboardingStep]

    private let onComplete: @MainActor @Sendable () async -> Void
    private let onSkip: (@MainActor @Sendable (String) async -> Void)?
    private let onStepAppear: (@MainActor @Sendable (String) async -> Void)?
    private let onError: (@MainActor @Sendable (any Error) async -> Void)?

    init(
        steps: [OnboardingStep],
        initialStepIndex: Int,
        onComplete: @escaping @MainActor @Sendable () async -> Void,
        onSkip: (@MainActor @Sendable (String) async -> Void)?,
        onStepAppear: (@MainActor @Sendable (String) async -> Void)?,
        onError: (@MainActor @Sendable (any Error) async -> Void)?
    ) {
        self.steps = steps
        currentIndex = steps.indices.contains(initialStepIndex) ? initialStepIndex : 0
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onStepAppear = onStepAppear
        self.onError = onError
    }

    var activeStep: OnboardingStep? {
        guard steps.indices.contains(currentIndex) else { return nil }
        return steps[currentIndex]
    }

    var isLastStep: Bool { currentIndex == steps.count - 1 }

    func goBack() {
        guard currentIndex > 0 else { return }
        navigationDirection = .backward
        currentIndex -= 1
    }

    func goForward() {
        guard currentIndex < steps.count - 1 else { return }
        navigationDirection = .forward
        currentIndex += 1
    }

    func reportStepAppearance() async {
        if let activeStep { await onStepAppear?(activeStep.id) }
    }

    func handlePrimaryAction(step: OnboardingStep) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            if let beforeAdvance = step.beforeAdvance { try await beforeAdvance() }
        } catch {
            await onError?(error)
            return
        }
        if isLastStep { await onComplete() } else { goForward() }
    }

    func skip() async {
        guard !isPerformingAction, let step = activeStep else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        await onSkip?(step.id)
        if isLastStep { await onComplete() } else { goForward() }
    }
}
