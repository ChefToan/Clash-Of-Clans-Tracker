// LoadingView.swift
import SwiftUI
import Lottie

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Lottie loading animation
                LottieView(animation: .named("loading"))
                    .looping()
                    .frame(width: 100, height: 100)
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#1a1a2e"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }
}
