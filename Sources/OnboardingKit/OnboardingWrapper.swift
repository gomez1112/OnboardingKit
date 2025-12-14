//
//  OnboardingWrapper.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct OnboardingWrapper<Content: View>: View {
    @AppStorage(OnboardingManager.storageKey) private var lastSeenVersion: String = ""
    @State private var showOnboarding = false
    @State private var onboardingType: OnboardingType = .firstLaunch
    
    let currentVersion: String
    let appName: String
    let pages: [OnboardingPage]
    let features: [FeatureItem]
    let tintColor: Color
    let content: Content
    
    private enum OnboardingType {
        case none, firstLaunch, whatsNew
    }
    
    public init(
        appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App",
        currentVersion: String,
        pages: [OnboardingPage],
        features: [FeatureItem],
        tint: Color = .blue,
        @ViewBuilder content: () -> Content
    ) {
        self.appName = appName
        self.currentVersion = currentVersion
        self.pages = pages
        self.features = features
        self.tintColor = tint
        self.content = content()
    }
    
    public var body: some View {
        content
            .onAppear(perform: checkOnboardingStatus)
            .sheet(isPresented: $showOnboarding) {
                Group {
                    switch onboardingType {
                        case .firstLaunch:
                            PagedOnboardingView(appName: appName, pages: pages, tintColor: tintColor) {
                                completeOnboarding()
                            }
                        case .whatsNew:
                            WelcomeSheetView(appName: appName, features: features, tintColor: tintColor) {
                                completeOnboarding()
                            }
                        case .none:
                            ProgressView()
                    }
                }
#if os(macOS)
                .frame(width: 500, height: 600)
#endif
            }
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
        withAnimation {
            showOnboarding = false
            lastSeenVersion = currentVersion
        }
    }
}
