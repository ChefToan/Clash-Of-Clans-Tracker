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
                                    let allItems = unitData.heroes + unitData.pets + unitData.troops + unitData.darkTroops + unitData.siegeMachines + unitData.spells
                                    
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
                                    
                                    // Pets category
                                    if !unitData.pets.isEmpty {
                                        UnitCategoryView(
                                            title: "PETS",
                                            items: unitData.pets,
                                            progress: viewModel.calculateProgress(unitData.pets),
                                            color: Color(hex: "#FF9FF3")
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
}
