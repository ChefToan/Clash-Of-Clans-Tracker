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
                
                // Percentage text - dynamic positioning
                Text(String(format: "%.1f%%", value))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .position(
                        x: textPosition(for: value, in: geometry.size.width),
                        y: geometry.size.height / 2
                    )
            }
        }
        .frame(height: 24)
    }
    
    // Calculate optimal text position
    private func textPosition(for progress: Double, in width: CGFloat) -> CGFloat {
        let progressWidth = width * (progress / 100)
        let textWidth: CGFloat = 40 // Approximate width of percentage text
        let minPosition = width / 2 // Center position for low values
        
        // If progress is too low, center the text
        if progressWidth < width * 0.3 {
            return minPosition
        }
        
        // Otherwise, position at the end of the progress bar with some padding
        let endPosition = progressWidth - textWidth / 2 - 8
        return max(minPosition, min(endPosition, width - textWidth / 2))
    }
}
