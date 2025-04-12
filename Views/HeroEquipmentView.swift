// HeroEquipmentView.swift
import SwiftUI

struct HeroEquipmentView: View {
    let title: String
    let equipmentGroups: [[PlayerItem]]
    let progress: Double
    let calculator: ProgressCalculator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ProgressBar(value: progress, color: Color(hex: "#9b59b6"))
                .frame(height: 20)
                .padding(.horizontal)
            
            // Display each hero's equipment in a section
            VStack(spacing: 15) {
                // Barbarian King Equipment
                if !equipmentGroups[0].isEmpty {
                    equipmentGroupView(items: equipmentGroups[0])
                }
                
                // Archer Queen Equipment
                if !equipmentGroups[1].isEmpty {
                    equipmentGroupView(items: equipmentGroups[1])
                }
                
                // Minion Prince Equipment
                if !equipmentGroups[2].isEmpty {
                    equipmentGroupView(items: equipmentGroups[2])
                }
                
                // Grand Warden Equipment
                if !equipmentGroups[3].isEmpty {
                    equipmentGroupView(items: equipmentGroups[3])
                }
                
                // Royal Champion Equipment
                if !equipmentGroups[4].isEmpty {
                    equipmentGroupView(items: equipmentGroups[4])
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding(.vertical, 5)
        .background(Constants.bgCard)
        .cornerRadius(Constants.innerCornerRadius)
        .padding(.horizontal, 6)
    }
    
    private func equipmentGroupView(items: [PlayerItem]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // Equipment items in a grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 10) {
                ForEach(items) { item in
                    ItemView(item: item)
                }
            }
            
            // Small divider between hero equipment groups
            if items != equipmentGroups[4] { // Don't add divider after last group
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.vertical, 5)
            }
        }
    }
}
