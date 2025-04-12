// PlayerStatsView.swift
import SwiftUI

struct PlayerStatsView: View {
    let player: Player
    let isLegendLeague: Bool
    let onClaimProfile: () -> Void
    let onBackToSearch: () -> Void
    
    @StateObject private var viewModel = PlayerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Action buttons
                HStack(spacing: 15) {
                    // Add to My Profile Button
                    Button(action: {
                        onClaimProfile()
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.headline)
                            Text("Add to My Profile")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.systemBlue))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // New Search Button
                    Button(action: {
                        onBackToSearch()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.headline)
                            Text("New Search")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.systemGreen))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Player Profile section with updated UI
                PlayerProfileView(player: player)
                .padding(.horizontal)
                
                // League Info section with updated UI
                LeagueInfoView(
                    player: player,
                    rankingsData: viewModel.rankingsData
                )
                .padding(.horizontal)
                
                // Trophy progression section
                if isLegendLeague {
                    TrophyProgressionView(player: player)
                    .padding(.horizontal)
                }
                
                // Player stats section
                VStack(spacing: 0) {
                    Text("PLAYER STATS")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.3))
                    
                    VStack(spacing: 0) {
                        // Level
                        SimpleStatRow(
                            label: "Level",
                            value: "\(player.expLevel)",
                            iconColor: Constants.blue
                        )
                        
                        // Capital Contribution
                        SimpleStatRow(
                            label: "Capital Contribution",
                            value: player.clanCapitalContributions.formatted,
                            iconColor: Color.gray
                        )
                        
                        // Attacks Won
                        SimpleStatRow(
                            label: "Attacks Won",
                            value: "\(player.attackWins)",
                            iconColor: .clear
                        )
                        
                        // Defenses Won
                        SimpleStatRow(
                            label: "Defenses Won",
                            value: "\(player.defenseWins)",
                            iconColor: .clear
                        )
                        
                        // War Stars Won
                        SimpleStatRow(
                            label: "War Stars Won",
                            value: "\(player.warStars)",
                            iconColor: .clear
                        )
                        
                        // Donations
                        SimpleStatRow(
                            label: "Donations",
                            value: "\(player.donations)",
                            iconColor: Constants.green
                        )
                        
                        // Donations Received
                        SimpleStatRow(
                            label: "Donations Received",
                            value: "\(player.donationsReceived)",
                            iconColor: Constants.red
                        )
                    }
                    .background(Constants.bgCard)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // UNIT PROGRESSION
                VStack(spacing: 0) {
                    Text("UNIT PROGRESSION")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.3))
                    
                    VStack(alignment: .center, spacing: 15) {
                        Text("TOTAL PROGRESSION")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        // Filter and process all units
                        let unitData = UnitSorter.filterAndSortItems(player)
                        let allItems = unitData.heroes + unitData.troops + unitData.darkTroops + unitData.siegeMachines + unitData.spells
                        
                        // Total progress bar
                        let totalProgress = viewModel.calculateProgress(allItems)
                        ProgressBar(value: totalProgress, color: Constants.blue)
                            .frame(height: 30)
                            .padding(.horizontal)
                        
                        // Heroes category
                        if !unitData.heroes.isEmpty {
                            UnitCategoryView(
                                title: "HEROES",
                                items: unitData.heroes,
                                progress: viewModel.calculateProgress(unitData.heroes),
                                color: Constants.orange
                            )
                        }
                        
                        // Regular troops category
                        if !unitData.troops.isEmpty {
                            UnitCategoryView(
                                title: "TROOPS",
                                items: unitData.troops,
                                progress: viewModel.calculateProgress(unitData.troops),
                                color: Constants.purple
                            )
                        }
                        
                        // Dark elixir troops
                        if !unitData.darkTroops.isEmpty {
                            UnitCategoryView(
                                title: "DARK ELIXIR TROOPS",
                                items: unitData.darkTroops,
                                progress: viewModel.calculateProgress(unitData.darkTroops),
                                color: Color(hex: "#6c5ce7")
                            )
                        }
                        
                        // Siege machines
                        if !unitData.siegeMachines.isEmpty {
                            UnitCategoryView(
                                title: "SIEGE MACHINES",
                                items: unitData.siegeMachines,
                                progress: viewModel.calculateProgress(unitData.siegeMachines),
                                color: Color(hex: "#d35400")
                            )
                        }
                        
                        // Spells
                        if !unitData.spells.isEmpty {
                            UnitCategoryView(
                                title: "SPELLS",
                                items: unitData.spells,
                                progress: viewModel.calculateProgress(unitData.spells),
                                color: Color(hex: "#00cec9")
                            )
                        }
                    }
                    .padding(.vertical)
                    .background(Constants.bgCard)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Bottom spacing
                Spacer()
                    .frame(height: 50)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.player = player
            
            // Check if in Legend League and load rankings data
            if let league = player.league, league.name.contains("Legend") {
                viewModel.isLegendLeague = true
                viewModel.loadPlayerRankings(tag: player.tag)
            }
        }
    }
}
