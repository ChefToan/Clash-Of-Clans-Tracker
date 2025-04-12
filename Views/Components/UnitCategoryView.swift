//  UnitCategoryView.swift
import SwiftUI

struct UnitCategoryView: View {
    let title: String
    let items: [PlayerItem]
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ProgressBar(value: progress, color: color)
                .frame(height: 20)
                .padding(.horizontal)
            
            // Only show items in a grid without empty placeholders
            if !items.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 8), spacing: 10) {
                    ForEach(items) { item in
                        ItemView(item: item)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .padding(.vertical, 5)
        .background(Constants.bgCard)
        .cornerRadius(Constants.innerCornerRadius)
        .padding(.horizontal, 6)
    }
}
