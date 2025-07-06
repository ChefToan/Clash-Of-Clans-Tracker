// ProgressBar.swift
import SwiftUI

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (value / 100))
                    .animation(.easeOut(duration: 0.3), value: value)
                
                // Percentage text - right aligned
                HStack {
                    Spacer()
                    Text(String(format: "%.1f%%", value))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                }
            }
        }
        .frame(height: 24)
    }
}
