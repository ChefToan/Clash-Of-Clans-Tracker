//  ItemView.swift
import SwiftUI

struct ItemView: View {
    let item: PlayerItem
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .cornerRadius(Constants.innerCornerRadius/2) // Using half the value for smaller items
            
            Text("\(item.level)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(4)
                .background(
                    item.isMaxed ? Constants.yellow : Color.black.opacity(0.7)
                )
                .foregroundColor(item.isMaxed ? .black : .white)
                .cornerRadius(Constants.innerCornerRadius/3) // Even smaller for the level indicator
                .padding(2)
        }
    }
}
