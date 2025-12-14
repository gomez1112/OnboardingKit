//
//  WelcomeSheetView.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct WelcomeSheetView: View {
    let appName: String
    let features: [FeatureItem]
    let tintColor: Color
    let onContinue: () -> Void
    
    @State private var isAnimating = false
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 10) {
                        Text("What's New in")
                            .font(.system(size: 30, weight: .bold))
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : -20)
                        
                        Text(appName)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(tintColor)
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : -20)
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 50)
                    
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                            HStack(alignment: .top, spacing: 16) {
                                OnboardingImageView(icon: feature.icon, tintColor: tintColor, symbolColor: feature.iconColor, size: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.title)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                    Text(feature.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding()
                            .background(feature.backgroundColor)
                            .cornerRadius(12)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(x: isAnimating ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2 + (Double(index) * 0.1)), value: isAnimating)
                        }
                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            
            VStack {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 500)
                        .frame(height: 50)
                        .background(tintColor)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: isAnimating)
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
            }
            .background(.regularMaterial)
        }
#if os(iOS)
        .interactiveDismissDisabled()
#endif
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.easeOut(duration: 0.6)) {
                    isAnimating = true
                }
            }
        }
    }
}
