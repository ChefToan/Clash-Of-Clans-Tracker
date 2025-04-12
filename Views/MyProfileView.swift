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
