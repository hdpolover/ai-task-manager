//
//  AIFloatingActionButton.swift
//  ai-task-manager
//
//  Floating AI Assistant Button for Quick Access
//

import SwiftUI

struct AIFloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var showPulse = true
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Pulse effect
                if showPulse {
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(showPulse ? 1.2 : 1.0)
                        .opacity(showPulse ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                            value: showPulse
                        )
                }
                
                // AI Icon
                VStack(spacing: 2) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("AI")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { 
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
        .onAppear {
            // Start pulse animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showPulse.toggle()
            }
        }
    }
}

#Preview {
    AIFloatingActionButton(action: {})
        .padding()
}
