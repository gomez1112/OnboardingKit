//
//  PagedOnboardingView.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct PagedOnboardingView: View {
    let appName: String
    let pages: [OnboardingPage]
    let tintColor: Color
    let onFinish: () -> Void
    
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    public var body: some View {
        // Changed to ZStack so the TabView can fill the screen behind controls
        ZStack {
            
            // 1. Background Layer (Pages)
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 24) {
                        Spacer()
                        
                        OnboardingImageView(icon: page.icon, tintColor: tintColor, symbolColor: page.iconColor, size: 100)
                            .scaleEffect(isAnimating ? 1 : 0.5)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: isAnimating)
                            .id("image-\(index)")
                        
                        Text(page.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .offset(y: isAnimating ? 0 : 20)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)
                        
                        Text(page.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 30)
                            .frame(maxWidth: 450)
                            .offset(y: isAnimating ? 0 : 20)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)
                        
                        Spacer()
                    }
                    .tag(index)
                    // Full screen configuration
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(page.backgroundColor)
                }
            }
#if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
#else
            .tabViewStyle(.page(indexDisplayMode: .never))
#endif
            .ignoresSafeArea() // Ensure background colors fill edges
            
            // 2. Foreground Layer (Controls)
            VStack {
                // Top: Skip Button
                HStack {
                    Spacer()
                    Button(action: onFinish) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(tintColor)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .opacity(isAnimating ? 1 : 0)
                }
                .padding(.top, 50) // Adjust for safe area since we ignored it
                .padding(.trailing, 20)
                
                Spacer()
                
                // Bottom: Indicators & Button
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? tintColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    Button(action: {
                        handleNextButton()
                    }) {
                        Text(getButtonTitle())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: 500)
                            .frame(height: 50)
                            .background(tintColor)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .offset(y: isAnimating ? 0 : 50)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isAnimating)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50) // Adjust for safe area
            }
        }
#if os(iOS)
        .interactiveDismissDisabled()
#endif
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isAnimating = true
                }
            }
        }
    }
    
    private func getButtonTitle() -> String {
        let page = pages[currentPage]
        if let customTitle = page.actionButtonTitle {
            return customTitle
        }
        return currentPage == pages.count - 1 ? "Get Started" : "Next"
    }
    
    private func handleNextButton() {
        let page = pages[currentPage]
        if let action = page.action {
            action()
            advancePage()
        } else {
            advancePage()
        }
    }
    
    private func advancePage() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            onFinish()
        }
    }
}
