// SimpleStatRow.swift
import SwiftUI

struct SimpleStatRow: View {
    let label: String
    let value: String
    var iconColor: Color? = nil
    var iconImage: String? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            
            Spacer()
            
            if let iconImage = iconImage, let image = UIImage(named: iconImage) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 5)
            } else if let iconColor = iconColor, iconColor != .clear {
                Rectangle()
                    .fill(iconColor)
                    .frame(width: 20, height: 20)
                    .cornerRadius(5)
                    .padding(.trailing, 5)
            }
            
            Text(value)
                .fontWeight(.bold)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Constants.bgCard)
        
        Divider()
            .background(Color.gray.opacity(0.3))
            .padding(.horizontal)
    }
}
