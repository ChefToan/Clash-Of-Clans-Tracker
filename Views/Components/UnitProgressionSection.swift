// UnitProgressionSection.swift
import SwiftUI

struct UnitProgressionSection: View {
    let player: Player
    let calculator: ProgressCalculator
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("UNIT PROGRESSION")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Constants.headerTextColor)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Constants.headerBackground)
            
            // Content
            VStack(alignment: .center, spacing: 15) {
                Text("TOTAL PROGRESSION")
                    .font(.headline)
                    .padding(.top, 10)
                
                // Filter and process all units
                let unitData = UnitSorter.filterAndSortItems(player)
                
                // Calculate all items for total progress
                let allHeroEquipments = unitData.heroEquipment.flatMap { $0 }
                let allItems = unitData.heroes + allHeroEquipments + unitData.pets + unitData.troops + unitData.darkTroops + unitData.siegeMachines + unitData.spells
                
                // Total progress bar
                let totalProgress = calculator.calculateProgress(allItems)
                ProgressBar(value: totalProgress, color: Constants.blue)
                    .frame(height: 30)
                    .padding(.horizontal)
                
                // No items case - add placeholder to maintain consistent sizing
                if allItems.isEmpty {
                    VStack(spacing: 12) {
                        Text("No progression data available")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 20)
                        
                        // Add empty space to ensure minimum height
                        Spacer()
                            .frame(height: 40)
                    }
                    .frame(minHeight: 150)
                }
                
                // Heroes category
                if !unitData.heroes.isEmpty {
                    UnitCategoryView(
                        title: "HEROES",
                        items: unitData.heroes,
                        progress: calculator.calculateProgress(unitData.heroes),
                        color: Constants.orange
                    )
                }
                
                // Hero Equipment category
                if !unitData.heroEquipment.flatMap({ $0 }).isEmpty {
                    HeroEquipmentView(
                        title: "HERO EQUIPMENT",
                        equipmentGroups: unitData.heroEquipment,
                        progress: calculator.calculateProgress(unitData.heroEquipment.flatMap { $0 }),
                        calculator: calculator
                    )
                }
                
                // Pets category
                if !unitData.pets.isEmpty {
                    UnitCategoryView(
                        title: "PETS",
                        items: unitData.pets,
                        progress: calculator.calculateProgress(unitData.pets),
                        color: Color(hex: "#FF9FF3")
                    )
                }
                
                // Regular troops category
                if !unitData.troops.isEmpty {
                    UnitCategoryView(
                        title: "TROOPS",
                        items: unitData.troops,
                        progress: calculator.calculateProgress(unitData.troops),
                        color: Constants.purple
                    )
                }
                
                // Dark elixir troops
                if !unitData.darkTroops.isEmpty {
                    UnitCategoryView(
                        title: "DARK ELIXIR TROOPS",
                        items: unitData.darkTroops,
                        progress: calculator.calculateProgress(unitData.darkTroops),
                        color: Color(hex: "#6c5ce7")
                    )
                }
                
                // Siege machines
                if !unitData.siegeMachines.isEmpty {
                    UnitCategoryView(
                        title: "SIEGE MACHINES",
                        items: unitData.siegeMachines,
                        progress: calculator.calculateProgress(unitData.siegeMachines),
                        color: Color(hex: "#d35400")
                    )
                }
                
                // Spells
                if !unitData.spells.isEmpty {
                    UnitCategoryView(
                        title: "SPELLS",
                        items: unitData.spells,
                        progress: calculator.calculateProgress(unitData.spells),
                        color: Color(hex: "#00cec9")
                    )
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
            .background(Constants.cardBackground)
        }
        .background(Constants.background)
        .cornerRadius(Constants.cornerRadius)
    }
}
