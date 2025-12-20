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
    let animationConfiguration: OnboardingAnimationConfiguration
    let onFinish: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isPrimaryButtonFocused: Bool
    @FocusState private var isSkipButtonFocused: Bool
    @State private var currentPage = 0
    @State private var previousPage = 0
    @State private var showButtons = false
    @State private var indicatorPulse = false
    
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
        animationConfiguration: OnboardingAnimationConfiguration = .default,
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.appName = appName
        self.pages = pages
        self.tintColor = tintColor
        self.animationConfiguration = animationConfiguration
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
                    Button("Skip") {
                        finishFlow()
                    }
                        .font(.subheadline)
                        .foregroundStyle(tintColor)
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Skip onboarding")
                        .focused($isSkipButtonFocused)
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
                            .offset(y: (indicatorPulse && currentPage == index) ? -2 : 0)
                            .animation(animationConfiguration.microInteractionAnimation(reduceMotion: reduceMotion), value: indicatorPulse)
                            .animation(animationConfiguration.pageAnimation(reduceMotion: reduceMotion), value: currentPage)
                            .accessibilityHidden(true)
                    }
                }
                
                // Primary button
                Button(action: handleNextButton) {
                    Text(buttonTitle)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: 520)
                        .frame(minHeight: 48)
                        .background(tintColor)
                        .clipShape(.rect(cornerRadius: 14, style: .continuous))
                        .shadow(radius: 5) // system default
                }
                .buttonStyle(OnboardingInteractiveButtonStyle(
                    animationConfiguration: animationConfiguration,
                    reduceMotion: reduceMotion
                ))
                .accessibilityLabel(buttonTitle)
                .focused($isPrimaryButtonFocused)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            .background(.regularMaterial)
            .opacity(showButtons ? 1 : 0.6)
            .animation(animationConfiguration.pageAnimation(reduceMotion: reduceMotion), value: showButtons)
        }
        
#if os(iOS)
        .interactiveDismissDisabled()
#endif
        .onAppear {
            isPrimaryButtonFocused = true
            withAnimation(animationConfiguration.pageAnimation(reduceMotion: reduceMotion)) {
                showButtons = true
            }
        }
        .onChange(of: currentPage) { oldValue, _ in
            previousPage = oldValue
        }
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
            advance(to: currentPage + 1)
        } else {
            finishFlow()
        }
    }

    @MainActor
    private func advance(to newPage: Int) {
        guard newPage != currentPage else { return }
        let direction: OnboardingAnimationConfiguration.Direction = newPage > currentPage ? .forward : .backward
        previousPage = currentPage
        if reduceMotion {
            currentPage = newPage
        } else {
            withAnimation(animationConfiguration.pageAnimation(reduceMotion: reduceMotion)) {
                currentPage = newPage
            }
        }
        animationConfiguration.firePrimaryHapticIfNeeded()
        triggerMicroIndicatorFeedback(direction: direction)
    }

    @MainActor
    private func finishFlow() {
        if reduceMotion {
            onFinish()
        } else {
            withAnimation(Animation.easeOut(duration: animationConfiguration.duration)) {
                showButtons = false
            }
            Task { @MainActor in
                let delay = Duration.seconds(animationConfiguration.duration * 0.9)
                try? await Task.sleep(for: delay)
                onFinish()
            }
        }
    }

    private func triggerMicroIndicatorFeedback(direction: OnboardingAnimationConfiguration.Direction) {
        // Tiny directional parallax to keep indicators lively.
        // Intentionally no-op on reduce motion to honor accessibility settings.
        guard !reduceMotion else { return }
        let animation = animationConfiguration.microInteractionAnimation(reduceMotion: reduceMotion)
        withAnimation(animation) {
            indicatorPulse.toggle()
        }
    }
    
    // MARK: Platform-specific page containers
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    private var iOSPageView: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                PageView(
                    page: page,
                    tintColor: tintColor,
                    animationConfiguration: animationConfiguration,
                    isActive: currentPage == index,
                    direction: direction(for: index)
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .transaction { transaction in
            transaction.animation = animationConfiguration.pageAnimation(reduceMotion: reduceMotion)
        }
    }
    #endif

    private var macPageView: some View {
        ZStack {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                if currentPage == index {
                    PageView(
                        page: page,
                        tintColor: tintColor,
                        animationConfiguration: animationConfiguration,
                        isActive: currentPage == index,
                        direction: direction(for: index)
                    )
                    .transition(animationConfiguration.transition(
                        for: direction(for: index),
                        reduceMotion: reduceMotion
                    ))
                }
            }
        }
        .animation(animationConfiguration.pageAnimation(reduceMotion: reduceMotion), value: currentPage)
    }

    private func direction(for index: Int) -> OnboardingAnimationConfiguration.Direction {
        index >= previousPage ? .forward : .backward
    }
}
private struct PageView: View {
    let page: OnboardingPage
    let tintColor: Color
    let animationConfiguration: OnboardingAnimationConfiguration
    let isActive: Bool
    let direction: OnboardingAnimationConfiguration.Direction

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false
    @State private var parallaxOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            page.backgroundColor
            
            VStack(spacing: 24) {
                Spacer()

                OnboardingImageView(
                    icon: page.icon,
                    tintColor: tintColor,
                    symbolColor: page.iconColor,
                    size: 100,
                    accessibilityLabel: page.title
                )
                .scaleEffect(animate ? 1 : 0.6)
                .opacity(animate ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: animationConfiguration.springResponse, dampingFraction: animationConfiguration.springDampingFraction).delay(0.05), value: animate)

                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .offset(y: animate ? 0 : 18)
                    .opacity(animate ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: animationConfiguration.duration).delay(0.12), value: animate)
                    .accessibilityAddTraits(.isHeader)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 30)
                    .frame(maxWidth: 520)
                    .offset(y: animate ? 0 : 18)
                    .opacity(animate ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: animationConfiguration.duration).delay(0.20), value: animate)

                Spacer()
            }
            .padding(.top, 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(page.title). \(page.description)")
        }
        .ignoresSafeArea()
        .offset(x: reduceMotion ? 0 : parallaxOffset)
        .scaleEffect(reduceMotion ? 1 : (isActive ? 1 : 0.98))
        .onAppear {
            // Re-trigger animation when the page becomes visible
            animate = false
            DispatchQueue.main.async { animate = true }
            updateParallax()
        }
        .onChange(of: isActive) { _, active in
            guard active else { return }
            animate = false
            DispatchQueue.main.async { animate = true }
            updateParallax()
        }
    }

    private func updateParallax() {
        guard !reduceMotion else { return }
        let offset: CGFloat = direction == .forward ? 10 : -10
        parallaxOffset = offset
        withAnimation(animationConfiguration.pageAnimation(reduceMotion: reduceMotion)) {
            parallaxOffset = 0
        }
    }
}
