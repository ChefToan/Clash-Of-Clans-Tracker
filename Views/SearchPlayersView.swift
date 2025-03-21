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

struct SearchPlayersView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some View {
        ZStack {
            Constants.bgDark.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                Text("Clash of Clans Tracker")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Constants.blue)
                
                if viewModel.showTimezoneSelection, let player = viewModel.player {
                    // Show timezone selection when adding to My Profile
                    TimezoneSelectionView(
                        playerName: player.name,
                        onContinue: {
                            // Save to My Profile after timezone is selected
                            Task {
                                await viewModel.completeProfileSave(player)
                            }
                        },
                        onCancel: {
                            // Return to player stats view
                            viewModel.showTimezoneSelection = false
                            viewModel.showPlayerStats = true
                        }
                    )
                } else if viewModel.showPlayerStats, let player = viewModel.player {
                    // Show player stats (now directly after search)
                    PlayerStatsView(
                        player: player,
                        isLegendLeague: playerViewModel.isLegendLeague,
                        onClaimProfile: {
                            // Show timezone selection first
                            Task {
                                await viewModel.saveProfile(player)
                            }
                        },
                        onBackToSearch: {
                            viewModel.resetToSearchState()
                        }
                    )
                    .onAppear {
                        // If player is in Legend League, load their rankings data
                        if let league = player.league, league.name.contains("Legend") {
                            playerViewModel.loadPlayer(tag: player.tag)
                        }
                    }
                } else {
                    // Main search view
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
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            VStack(spacing: 15) {
                                VStack(alignment: .leading) {
                                    Text("Player Tag")
                                        .font(.caption)
                                        .foregroundColor(Constants.textMuted)
                                        .padding(.leading, 5)
                                    
                                    // Custom Player Tag Input with # Prefix
                                    HStack(spacing: 0) {
                                        Text("#")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 14)
                                            .background(Constants.bgInput)
                                            .cornerRadius(8, corners: [.topLeft, .bottomLeft])

                                        TextField("Enter Player Tag", text: $viewModel.playerTag)
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 8)
                                            .background(Constants.bgInput)
                                            .foregroundColor(.white)
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
                                
                                Button(action: viewModel.searchPlayer) {
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
                        .background(Constants.bgCard)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
