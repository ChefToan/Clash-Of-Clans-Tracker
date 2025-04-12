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
                
                // Player Profile section
                PlayerProfileView(player: player)
                    .padding(.horizontal)
                
                // League Info section
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
                PlayerStatsSection(player: player)
                    .padding(.horizontal)
                
                // Unit progression section
                UnitProgressionSection(
                    player: player,
                    calculator: viewModel
                )
                .padding(.horizontal)
                
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
