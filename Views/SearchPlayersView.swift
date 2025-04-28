// SearchPlayersView.swift
import SwiftUI

// Add this extension to support rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// SearchPlayersView.swift
struct SearchPlayersView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @ObservedObject var tabState: TabState
    
    var body: some View {
        ZStack {
            Constants.background.edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.showPlayerStats, let player = viewModel.player {
                    // Show player stats (now directly after search)
                    PlayerStatsView(
                        player: player,
                        isLegendLeague: playerViewModel.isLegendLeague,
                        onClaimProfile: {
                            // Save profile directly without timezone selection
                            Task {
                                await viewModel.saveProfile(player)
                            }
                        },
                        onBackToSearch: {
                            viewModel.resetToSearchState()
                        },
                        onRefresh: {
                            await viewModel.refreshPlayerData()
                            
                            // Update playerViewModel with the refreshed player
                            if let refreshedPlayer = viewModel.player {
                                playerViewModel.player = refreshedPlayer
                                if let league = refreshedPlayer.league, league.name.contains("Legend") {
                                    playerViewModel.isLegendLeague = true
                                    playerViewModel.loadPlayerRankings(tag: refreshedPlayer.tag)
                                } else {
                                    playerViewModel.isLegendLeague = false
                                    playerViewModel.rankingsData = nil
                                }
                            }
                        }
                    )
                    .id(player.tag + String(player.trophies)) // Force view to refresh when player data changes
                    .onAppear {
                        // If player is in Legend League, load their rankings data
                        if let league = player.league, league.name.contains("Legend") {
                            playerViewModel.player = player
                            playerViewModel.isLegendLeague = true
                            playerViewModel.loadPlayerRankings(tag: player.tag)
                        } else {
                            playerViewModel.player = player
                            playerViewModel.isLegendLeague = false
                        }
                    }
                } else {
                    // Main search view - No title on this screen
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Clash Logo
                        ZStack {
                            Rectangle()
                                .fill(Constants.orange)
                                .frame(width: 80, height: 80)
                                .cornerRadius(20)
                                .rotationEffect(.degrees(45))
                                .shadow(radius: 5)
                            
                            Rectangle()
                                .fill(Constants.red)
                                .frame(width: 60, height: 60)
                                .cornerRadius(15)
                                .rotationEffect(.degrees(45))
                            
                            Rectangle()
                                .fill(Constants.yellow)
                                .frame(width: 40, height: 40)
                                .cornerRadius(10)
                                .rotationEffect(.degrees(45))
                        }
                        .padding(.bottom, 20)
                        
                        // Search Container
                        VStack(spacing: 15) {
                            Text("Welcome to Clash of Clans Tracker")
                                .foregroundColor(.primary)
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            VStack(spacing: 15) {
                                VStack(alignment: .leading) {
                                    Text("Player Tag")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 5)
                                    
                                    // Custom Player Tag Input with # Prefix
                                    HStack(spacing: 0) {
                                        Text("#")
                                            .foregroundColor(.primary)
                                            .font(.headline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 14)
                                            .background(Constants.cardBackground)
                                            .cornerRadius(8, corners: [.topLeft, .bottomLeft])

                                        TextField("Enter Player Tag", text: $viewModel.playerTag)
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 8)
                                            .background(Constants.cardBackground)
                                            .foregroundColor(.primary)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .keyboardType(.asciiCapable)
                                            .cornerRadius(8, corners: [.topRight, .bottomRight])
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    HapticManager.shared.mediumImpactFeedback()
                                    viewModel.searchPlayer()
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.white)
                                        
                                        Text("Search")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Constants.blue)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Constants.cardBackground)
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 400)
                    
                    Spacer()
                }
            }
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Success overlay
            if viewModel.showSuccess {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Constants.green)
                        Text("Profile saved successfully!")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: viewModel.showSuccess)
                .zIndex(100)
            }
        }
        .navigationBarHidden(!viewModel.showPlayerStats) // Hide navigation bar on search input screen
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(viewModel.showPlayerStats ? "Search Players" : "")
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: tabState.shouldResetSearch) { _, newValue in
            if newValue {
                viewModel.resetToSearchState()
            }
        }
    }
}
