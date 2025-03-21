// MyProfileView.swift
import SwiftUI
import SwiftData

struct MyProfileView: View {
    @StateObject private var viewModel = MyProfileViewModel()
    @State private var isFirstLoad = true
    
    var body: some View {
        ZStack {
            Constants.bgDark.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                Text("My Profile")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Constants.blue)
                
                // Refresh button below header
                if !viewModel.isLoading, viewModel.player != nil {
                    Button {
                        Task {
                            await viewModel.refreshProfile()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Profile")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Constants.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if let player = viewModel.player {
                    // Player profile content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Player Profile section
                            PlayerProfileView(player: player)
                                .padding(.horizontal)
                            
                            // League Info section
                            LeagueInfoView(
                                player: player,
                                rankingsData: viewModel.rankingsData
                            )
                            .padding(.horizontal)
                            
                            // Trophy progression section for Legend League
                            if viewModel.isLegendLeague {
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
                            .padding(.vertical, 10)
                            
                            // UNIT PROGRESSION
                            if let troops = player.troops, !troops.isEmpty {
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
                                        
                                        // Total progress bar
                                        let allItems = getAllItems(player)
                                        let totalProgress = viewModel.calculateProgress(allItems)
                                        ProgressBar(value: totalProgress, color: Constants.blue)
                                            .frame(height: 30)
                                            .padding(.horizontal)
                                        
                                        // Heroes category
                                        if let heroes = player.heroes, !heroes.isEmpty {
                                            UnitCategoryView(
                                                title: "HEROES",
                                                items: heroes,
                                                progress: viewModel.calculateProgress(heroes),
                                                color: Constants.orange
                                            )
                                        }
                                        
                                        // Troops categories
                                        if !troops.isEmpty {
                                            let regularTroops = troops.filter {
                                                !viewModel.isSuperTroop($0) &&
                                                !viewModel.isDarkElixirTroop($0) &&
                                                !viewModel.isSiegeMachine($0)
                                            }
                                            
                                            if !regularTroops.isEmpty {
                                                UnitCategoryView(
                                                    title: "TROOPS",
                                                    items: regularTroops,
                                                    progress: viewModel.calculateProgress(regularTroops),
                                                    color: Constants.purple
                                                )
                                            }
                                            
                                            let darkTroops = troops.filter { viewModel.isDarkElixirTroop($0) }
                                            if !darkTroops.isEmpty {
                                                UnitCategoryView(
                                                    title: "DARK ELIXIR TROOPS",
                                                    items: darkTroops,
                                                    progress: viewModel.calculateProgress(darkTroops),
                                                    color: Color(hex: "#6c5ce7")
                                                )
                                            }
                                        }
                                        
                                        // Spells
                                        if let spells = player.spells, !spells.isEmpty {
                                            UnitCategoryView(
                                                title: "SPELLS",
                                                items: spells,
                                                progress: viewModel.calculateProgress(spells),
                                                color: Color(hex: "#00cec9")
                                            )
                                        }
                                    }
                                    .padding(.vertical)
                                    .background(Constants.bgCard)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: 20)
                        }
                    }
                } else {
                    // No profile claimed view
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(Constants.blue)
                        
                        Text("No Profile Claimed")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Search for a player and claim it as your profile")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Only load profile once to avoid infinite loop
            if isFirstLoad {
                Task {
                    await viewModel.loadProfile()
                    isFirstLoad = false
                }
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Helper functions for calculating progress
    private func getAllItems(_ player: Player) -> [PlayerItem] {
        var allItems: [PlayerItem] = []
        
        if let troops = player.troops {
            allItems.append(contentsOf: troops)
        }
        
        if let heroes = player.heroes {
            allItems.append(contentsOf: heroes)
        }
        
        if let spells = player.spells {
            allItems.append(contentsOf: spells)
        }
        
        if let equipment = player.heroEquipment {
            allItems.append(contentsOf: equipment)
        }
        
        return allItems
    }
}
