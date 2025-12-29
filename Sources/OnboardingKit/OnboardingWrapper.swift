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
    
    let currentVersion: String
    let appName: String
    let pages: [OnboardingPage]
    let features: [FeatureItem]
    let tintColor: Color
    let animationConfiguration: OnboardingAnimationConfiguration
    let content: Content

    fileprivate enum OnboardingType {
        case none, firstLaunch, whatsNew
    }
    
    /// Creates a wrapper that decides which onboarding experience to show.
    /// - Parameters:
    ///   - appName: Display name shown in onboarding UI. Defaults to the bundle name.
    ///   - currentVersion: Version string used to determine if onboarding should appear.
    ///   - pages: Pages shown during first-launch onboarding.
    ///   - features: Feature rows shown in the "What's New" sheet when the version changes.
    ///   - tint: Accent color applied to controls and imagery.
    ///   - content: The root view for your application.
    public init(
        appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App",
        currentVersion: String,
        pages: [OnboardingPage],
        features: [FeatureItem],
        tint: Color = .blue,
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.appName = appName
        self.currentVersion = currentVersion
        self.pages = pages
        self.features = features
        self.tintColor = tint
        self.animationConfiguration = animationConfiguration
        self.content = content()
    }

    /// The composed view that displays onboarding content when required.
    public var body: some View {
        content
            .onAppear(perform: checkOnboardingStatus)
#if os(iOS)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingPresentationView(
                    onboardingType: onboardingType,
                    appName: appName,
                    pages: pages,
                    features: features,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    completion: completeOnboarding
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
                    completion: completeOnboarding
                )
#if os(macOS)
                .frame(width: 500, height: 600)
#endif
            }
#endif
    }
    
    private func checkOnboardingStatus() {
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
    
    private func completeOnboarding() {
        if reduceMotion {
            showOnboarding = false
            lastSeenVersion = currentVersion
        } else {
            withAnimation(.easeOut(duration: animationConfiguration.duration)) {
                showOnboarding = false
                lastSeenVersion = currentVersion
            }
        }
    }
}

private struct OnboardingPresentationView: View {
    let onboardingType: OnboardingWrapper.OnboardingType
    let appName: String
    let pages: [OnboardingPage]
    let features: [FeatureItem]
    let tintColor: Color
    let animationConfiguration: OnboardingAnimationConfiguration
    let completion: () -> Void

    var body: some View {
        Group {
            switch onboardingType {
            case .firstLaunch:
                PagedOnboardingView(
                    appName: appName,
                    pages: pages,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    completion: completion
                )
            case .whatsNew:
                WelcomeSheetView(
                    appName: appName,
                    features: features,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    completion: completion
                )
            case .none:
                ProgressView()
            }
        }
    }
}
