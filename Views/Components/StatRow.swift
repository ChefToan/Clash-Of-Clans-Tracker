// StatRow.swift
import SwiftUI

struct StatRow: View {
    let label: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            
            Spacer()
            
            if iconColor != .clear {
                Rectangle()
                    .fill(iconColor)
                    .frame(width: 20, height: 20)
                    .cornerRadius(5)
                    .padding(.trailing, 5)
            }
            
            Text(value)
                .fontWeight(.bold)
        }
    }
}
