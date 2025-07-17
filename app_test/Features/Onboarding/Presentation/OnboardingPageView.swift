//
//  OnboardingPageView.swift
//  app_test
//
//  Individual Onboarding Page Component
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                // Hero Icon with background circle
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: page.imageName)
                        .font(.system(size: 60, weight: .regular, design: .rounded))
                        .foregroundStyle(.blue)
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: page.id)
                
                Spacer(minLength: 60)
                
                // Content Section
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 32)
                    
                    Text(page.description)
                        .font(.system(.title3, design: .default, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 80)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage.pages[0])
        .withDependencies()
}
