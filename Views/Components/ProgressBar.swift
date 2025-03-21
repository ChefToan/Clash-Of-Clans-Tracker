//  ProgressBar.swift
import SwiftUI

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: Constants.innerCornerRadius)
                    .fill(Color.gray.opacity(0.3))
                
                // Progress fill
                RoundedRectangle(cornerRadius: Constants.innerCornerRadius)
                    .fill(color)
                    .frame(width: min(CGFloat(value) / 100 * geometry.size.width, geometry.size.width))
                
                // Percentage text
                Text("\(String(format: "%.2f", value))%")
                    .foregroundColor(.white)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.trailing, 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
