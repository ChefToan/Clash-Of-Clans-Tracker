// MyProfileView.swift
import SwiftUI
import SwiftData

struct MyProfileView: View {
    @StateObject private var viewModel = MyProfileViewModel()
    @State private var isFirstLoad = true
    @State private var isRefreshing = false
    @EnvironmentObject var appState: AppState
    
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
                
                if viewModel.isLoading && !isRefreshing {
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
                                .frame(height: 20)
                        }
                    }
                    .refreshable {
                        isRefreshing = true
                        await viewModel.refreshProfile()
                        isRefreshing = false
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
                        
                        Button {
                            // Navigate to search tab
                            appState.selectedTab = .search
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Players")
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Constants.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 12)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Always refresh when the view appears to catch any changes
            Task {
                // Directly check if profile exists in the database
                let profileExists = await viewModel.checkIfProfileExists()
                print("MyProfileView onAppear - Profile exists: \(profileExists)")
                
                if profileExists {
                    await viewModel.loadProfile()
                } else {
                    // If no profile exists, make sure player is nil
                    viewModel.player = nil
                    viewModel.isLoading = false
                }
                
                isFirstLoad = false
            }
        }
        .onChange(of: appState.profileUpdated) { _, updated in
            if updated {
                print("MyProfileView detected profile update notification")
                // Profile was just updated, reload from database
                Task {
                    await viewModel.loadProfile()
                }
            }
        }
        .onChange(of: appState.profileRemoved) { _, removed in
            if removed {
                print("MyProfileView detected profile removal notification")
                // Profile was just removed, immediately clear the player
                viewModel.player = nil
                viewModel.isLoading = false
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
