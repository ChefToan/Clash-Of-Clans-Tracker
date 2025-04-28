// MyProfileView.swift
import SwiftUI
import SwiftData

struct MyProfileView: View {
    @StateObject private var viewModel = MyProfileViewModel()
    @ObservedObject var tabState: TabState
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
                            // Added top padding here to separate from blue header
                            PlayerProfileView(player: player)
                                .padding(.horizontal)
                                .padding(.top, 10) // Added padding at the top
                            
                            LeagueInfoView(
                                player: player,
                                rankingsData: viewModel.rankingsData
                            )
                            .padding(.horizontal)
                            
                            if viewModel.isLegendLeague {
                                TrophyProgressionView(player: player)
                                    .padding(.horizontal)
                            }
                            
                            PlayerStatsSection(player: player)
                                .padding(.horizontal)
                            
                            UnitProgressionSection(
                                player: player,
                                calculator: viewModel
                            )
                            .padding(.horizontal)
                            
                            Spacer()
                                .frame(height: 20)
                        }
                    }
                    .refreshable {
                        await viewModel.refreshProfile()
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
                            tabState.handleTabSelection(.search)
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Now")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Constants.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Load profile on first appear
            Task {
                await viewModel.loadProfile()
            }
        }
        .onChange(of: tabState.selectedTab) { _, newValue in
            // Only reload when selecting the profile tab
            if newValue == .profile {
                Task {
                    await viewModel.loadProfile()
                }
            }
        }
        .onChange(of: appState.profileRemoved) { _, removed in
            if removed {
                // Force a reload when profile is removed
                NotificationCenter.default.post(name: Notification.Name("ProfileRemoved"), object: nil)
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
