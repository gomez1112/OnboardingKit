//
//  OnboardingWrapper.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// Wraps your root view and automatically presents onboarding or "What's New" flows.
public struct OnboardingWrapper<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(OnboardingManager.storageKey) private var lastSeenVersion: String = ""
    @State private var showOnboarding = false
    @State private var onboardingType: OnboardingType = .firstLaunch

    @Binding private var presentation: OnboardingPresentation?
    let currentVersion: String
    let appName: String
    let pages: [OnboardingPage]
    let features: [FeatureItem]
    let tintColor: Color
    let animationConfiguration: OnboardingAnimationConfiguration
    let copy: OnboardingCopy
    let content: Content

    /// Creates a wrapper that decides which onboarding experience to show.
    /// - Parameters:
    ///   - appName: Display name shown in onboarding UI. Defaults to the bundle name.
    ///   - currentVersion: Version string used to determine if onboarding should appear.
    ///   - pages: Pages shown during first-launch onboarding.
    ///   - features: Feature rows shown in the "What's New" sheet when the version changes.
    ///   - tint: Accent color applied to controls and imagery.
    ///   - presentation: Optional binding used to present onboarding on demand.
    ///   - content: The root view for your application.
    public init(
        appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App",
        currentVersion: String,
        pages: [OnboardingPage],
        features: [FeatureItem],
        tint: Color = .blue,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        copy: OnboardingCopy = .default,
        presentation: Binding<OnboardingPresentation?> = .constant(nil),
        @ViewBuilder content: () -> Content
    ) {
        self.appName = appName
        self.currentVersion = currentVersion
        self.pages = pages
        self.features = features
        self.tintColor = tint
        self.animationConfiguration = animationConfiguration
        self.copy = copy
        self._presentation = presentation
        self.content = content()
    }

    /// The composed view that displays onboarding content when required.
    public var body: some View {
        content
            .onAppear(perform: checkOnboardingStatus)
            .onChange(of: presentation) { _, newValue in
                guard let newValue else { return }
                presentOnboarding(for: newValue)
            }
#if os(iOS)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingPresentationView(
                    onboardingType: onboardingType,
                    appName: appName,
                    pages: pages,
                    features: features,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    copy: copy,
                    completion: { @MainActor in
                        completeOnboarding()
                    }
                )
            }
#else
            .sheet(isPresented: $showOnboarding) {
                OnboardingPresentationView(
                    onboardingType: onboardingType,
                    appName: appName,
                    pages: pages,
                    features: features,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    copy: copy,
                    completion: { @MainActor in
                        completeOnboarding()
                    }
                )
#if os(macOS)
                .frame(width: 500, height: 600)
                .interactiveDismissDisabled()
#endif
            }
#endif
    }
    
    @MainActor
    private func checkOnboardingStatus() {
        if let presentation {
            presentOnboarding(for: presentation)
            return
        }
        if lastSeenVersion.isEmpty {
            onboardingType = .firstLaunch
            showOnboarding = true
        } else if lastSeenVersion != currentVersion {
            onboardingType = .whatsNew
            showOnboarding = true
        } else {
            showOnboarding = false
        }
    }
    
    @MainActor
    private func completeOnboarding() {
        if reduceMotion {
            showOnboarding = false
            lastSeenVersion = currentVersion
            presentation = nil
        } else {
            withAnimation(.easeOut(duration: animationConfiguration.duration)) {
                showOnboarding = false
                lastSeenVersion = currentVersion
                presentation = nil
            }
        }
    }

    @MainActor
    private func presentOnboarding(for presentation: OnboardingPresentation) {
        switch presentation {
        case .firstLaunch:
            onboardingType = .firstLaunch
        case .whatsNew:
            onboardingType = .whatsNew
        }
        showOnboarding = true
    }
}

fileprivate enum OnboardingType {
    case none, firstLaunch, whatsNew
}

/// Presentation options for manually triggering onboarding.
public enum OnboardingPresentation: Sendable, Equatable {
    case firstLaunch
    case whatsNew
}

private struct OnboardingPresentationView: View {
    let onboardingType: OnboardingType
    let appName: String
    let pages: [OnboardingPage]
    let features: [FeatureItem]
    let tintColor: Color
    let animationConfiguration: OnboardingAnimationConfiguration
    let copy: OnboardingCopy
    let completion: @MainActor @Sendable () -> Void

    var body: some View {
        Group {
            switch onboardingType {
            case .firstLaunch:
                PagedOnboardingView(
                    appName: appName,
                    pages: pages,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    copy: copy,
                    onFinish: completion
                )
            case .whatsNew:
                WelcomeSheetView(
                    appName: appName,
                    features: features,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    copy: copy,
                    onContinue: completion
                )
            case .none:
                ProgressView()
            }
        }
#if os(iOS)
        .toolbar(.hidden, for: .tabBar)
#endif
    }
}
