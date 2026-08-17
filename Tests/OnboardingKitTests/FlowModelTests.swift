import Testing
@testable import OnboardingKit

private enum TestError: Error { case vetoed }

@MainActor
private final class Recorder {
    var skipped: [String] = []
    var completionCount = 0
    var actionCount = 0
    var errors: [any Error] = []
}

@MainActor
private func makeModel(initialIndex: Int = 0, recorder: Recorder = Recorder()) -> OnboardingFlowModel {
    OnboardingFlowModel(
        steps: [.custom(id: "one", title: "One"), .custom(id: "two", title: "Two")],
        initialStepIndex: initialIndex,
        onComplete: { recorder.completionCount += 1 },
        onSkip: { recorder.skipped.append($0) },
        onStepAppear: nil,
        onError: { recorder.errors.append($0) }
    )
}

@Test @MainActor func navigationClampsAndHonorsBounds() {
    let model = makeModel(initialIndex: 99)
    #expect(model.currentIndex == 0)
    model.goBack()
    #expect(model.currentIndex == 0)
    model.goForward()
    #expect(model.currentIndex == 1)
    model.goForward()
    #expect(model.currentIndex == 1)
    model.goBack()
    #expect(model.currentIndex == 0)
}

@Test @MainActor func skipDoesNotRunActionAndCompletesLastStep() async {
    let recorder = Recorder()
    let model = makeModel(recorder: recorder)
    let step = OnboardingStep.custom(id: "one", title: "One", beforeAdvance: { recorder.actionCount += 1 })
    await model.skip()
    #expect(recorder.skipped == ["one"])
    #expect(recorder.actionCount == 0)
    #expect(model.currentIndex == 1)
    await model.skip()
    #expect(recorder.skipped == ["one", "two"])
    #expect(recorder.completionCount == 1)
    _ = step
}

@Test @MainActor func thrownActionVetoesNavigationAndForwardsError() async {
    let recorder = Recorder()
    let model = makeModel(recorder: recorder)
    let step = OnboardingStep.custom(id: "one", title: "One", beforeAdvance: { throw TestError.vetoed })
    await model.handlePrimaryAction(step: step)
    #expect(model.currentIndex == 0)
    #expect(model.isPerformingAction == false)
    #expect(recorder.errors.count == 1)
}
