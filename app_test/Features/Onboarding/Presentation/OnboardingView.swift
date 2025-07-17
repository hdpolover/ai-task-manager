//
//  OnboardingView.swift
//  app_test
//
//  Main Onboarding Flow View
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    let onComplete: () -> Void
    
    private let pages = OnboardingPage.pages
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                // Page Content
                TabView(selection: $viewModel.currentPageIndex) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentPageIndex)
                
                // Bottom Section
                bottomSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
            }
            .background(Color(.systemBackground))
        }
        .onChange(of: viewModel.isOnboardingCompleted) { completed in
            if completed {
                onComplete()
            }
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Close button (X)
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5))
                    )
            }
            
            Spacer()
            
            // Skip button
            if !viewModel.isLastPage {
                Button("Skip") {
                    viewModel.skipOnboarding()
                }
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 44)
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Page Control
            pageControl
            
            // Action Buttons
            actionButtons
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Page Control
    private var pageControl: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentPageIndex ? Color.blue : Color(.systemGray4))
                    .frame(
                        width: index == viewModel.currentPageIndex ? 20 : 8,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPageIndex)
                    .onTapGesture {
                        viewModel.goToPage(index)
                    }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Back Button
            if !viewModel.isFirstPage {
                Button(action: viewModel.previousPage) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(.body, weight: .medium))
                    }
                    .foregroundStyle(.blue)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1.5)
                    )
                }
                .transition(.opacity.combined(with: .scale))
            }
            
            // Primary Action Button
            Button(action: {
                if viewModel.isLastPage {
                    viewModel.completeOnboarding()
                } else {
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 6) {
                    Text(viewModel.isLastPage ? "Get Started" : "Continue")
                        .font(.system(.body, weight: .semibold))
                    
                    if !viewModel.isLastPage {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .foregroundStyle(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .scaleEffect(viewModel.isLastPage ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLastPage)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .withDependencies()
}
