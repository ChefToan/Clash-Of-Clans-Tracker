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
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            
            // Content
            VStack(alignment: .center, spacing: 15) {
                Text("TOTAL PROGRESSION")
                    .font(.headline)
                    .padding(.top, 10)
                
                // Filter and process all units
                let unitData = UnitSorter.filterAndSortItems(player)
                let allItems = unitData.heroes + unitData.pets + unitData.troops + unitData.darkTroops + unitData.siegeMachines + unitData.spells
                
                // Total progress bar
                let totalProgress = calculator.calculateProgress(allItems)
                ProgressBar(value: totalProgress, color: Constants.blue)
                    .frame(height: 30)
                    .padding(.horizontal)
                
                // Heroes category
                if !unitData.heroes.isEmpty {
                    UnitCategoryView(
                        title: "HEROES",
                        items: unitData.heroes,
                        progress: calculator.calculateProgress(unitData.heroes),
                        color: Constants.orange
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
            .padding(.vertical)
            .padding(.horizontal)
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
    }
}
