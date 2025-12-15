//
//  PagedOnboardingView.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// A paged, animated onboarding experience for first-launch flows.
public struct PagedOnboardingView: View {
    let appName: String
    let pages: [OnboardingPage]
    let tintColor: Color
    let onFinish: @MainActor () -> Void
    
    @State private var currentPage = 0
    
    /// Creates a paged onboarding view.
    /// - Parameters:
    ///   - appName: Name displayed in the header copy.
    ///   - pages: Pages to cycle through.
    ///   - tintColor: Accent color for controls and indicators.
    ///   - onFinish: Closure executed after the final page or when "Skip" is tapped.
    public init(
        appName: String,
        pages: [OnboardingPage],
        tintColor: Color = .blue,
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.appName = appName
        self.pages = pages
        self.tintColor = tintColor
        self.onFinish = onFinish
    }

    /// The visual representation of the paged onboarding experience.
    public var body: some View {
        ZStack {
            // Background (Pages)
#if os(iOS) || os(tvOS) || os(watchOS)
            iOSPageView
#elseif os(macOS)
            macPageView
#endif
        }
        .ignoresSafeArea()
        
        // Top controls (no hard-coded safe-area padding)
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                if shouldShowSkip {
                    Button("Skip") { onFinish() }
                        .font(.subheadline)
                        .foregroundStyle(tintColor)
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Skip onboarding")
                }
            }
            .padding(.trailing, 6)
            .padding(.top, 6)
        }
        
        // Bottom controls (no hard-coded safe-area padding)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? tintColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                            .accessibilityHidden(true)
                    }
                }
                
                // Primary button
                Button(action: handleNextButton) {
                    Text(buttonTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 520)
                        .frame(height: 52)
                        .background(tintColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(radius: 5) // system default
                }
                .buttonStyle(.plain)
                .accessibilityLabel(buttonTitle)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            .background(.regularMaterial)
        }
        
#if os(iOS)
        .interactiveDismissDisabled()
#endif
    }
    
    private var shouldShowSkip: Bool {
        pages.count > 1 && currentPage < pages.count - 1
    }
    
    private var buttonTitle: String {
        let page = pages[currentPage]
        if let custom = page.actionButtonTitle { return custom }
        return currentPage == pages.count - 1 ? "Get Started" : "Next"
    }
    
    @MainActor
    private func handleNextButton() {
        let page = pages[currentPage]
        page.action?()
        
        if currentPage < pages.count - 1 {
            withAnimation(.snappy) { currentPage += 1 }
        } else {
            onFinish()
        }
    }
    
    // MARK: Platform-specific page containers
    
    private var iOSPageView: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                PageView(page: page, tintColor: tintColor)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    private var macPageView: some View {
        ZStack {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                if currentPage == index {
                    PageView(page: page, tintColor: tintColor)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
        .animation(.default, value: currentPage)
    }
}
private struct PageView: View {
    let page: OnboardingPage
    let tintColor: Color
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            page.backgroundColor
            
            VStack(spacing: 24) {
                Spacer()
                
                OnboardingImageView(
                    icon: page.icon,
                    tintColor: tintColor,
                    symbolColor: page.iconColor,
                    size: 100
                )
                .scaleEffect(animate ? 1 : 0.6)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.05), value: animate)
                
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .offset(y: animate ? 0 : 18)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.12), value: animate)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 30)
                    .frame(maxWidth: 520)
                    .offset(y: animate ? 0 : 18)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.20), value: animate)
                
                Spacer()
            }
            .padding(.top, 10)
        }
        .ignoresSafeArea()
        .onAppear {
            // Re-trigger animation when the page becomes visible
            animate = false
            DispatchQueue.main.async { animate = true }
        }
    }
}
