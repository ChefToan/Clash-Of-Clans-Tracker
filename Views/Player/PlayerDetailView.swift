// PlayerDetailView.swift
import SwiftUI
import AlertToast

struct PlayerDetailView: View {
    let player: PlayerEssentials
    @ObservedObject var viewModel: SearchViewModel
    let onSaveProfile: () -> Void
    let onNewSearch: () -> Void
    @State private var isSavingProfile = false
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#1a1a2e"), Color(hex: "#0f0f1e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Action buttons
                    HStack(spacing: 15) {
                        Button {
                            if !isSavingProfile {
                                HapticManager.shared.mediumImpactFeedback()
                                isSavingProfile = true
                                onSaveProfile()
                            }
                        } label: {
                            HStack {
                                if isSavingProfile {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                }
                                Text("Save Profile")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSavingProfile ? Color.gray : Constants.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSavingProfile)
                        .scaleEffect(isSavingProfile ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSavingProfile)
                        
                        Button {
                            HapticManager.shared.lightImpactFeedback()
                            onNewSearch()
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("New Search")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    PlayerHeaderView(player: player)
                        .transition(.scale.combined(with: .opacity))
                    
                    if player.league?.name.contains("Legend") == true {
                        TrophyChartView(playerTag: player.playerTag)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    LeagueInfoView(player: player)
                        .transition(.scale.combined(with: .opacity))
                    
                    PlayerStatsView(player: player)
                        .transition(.scale.combined(with: .opacity))
                    
                    UnitProgressionView(player: player)
                        .transition(.scale.combined(with: .opacity))
                }
                .padding(.horizontal)
            }
            .refreshable {
                await performRefresh()
            }
        }
        .navigationTitle("Player Details")
        .navigationBarTitleDisplayMode(.inline)
        .toast(isPresenting: $viewModel.showSuccess) {
            AlertToast(
                type: .complete(Color.green),
                title: "Profile Saved!",
                subTitle: "Switching to your profile..."
            )
        }
        .toast(isPresenting: $viewModel.showError) {
            AlertToast(
                type: .error(Color.red),
                title: "Error",
                subTitle: viewModel.errorMessage
            )
        }
    }
    
    private func performRefresh() async {
        guard networkMonitor.isConnected else {
            HapticManager.shared.errorFeedback()
            return
        }
        
        HapticManager.shared.mediumImpactFeedback()
        await viewModel.refreshPlayer()
    }
}
