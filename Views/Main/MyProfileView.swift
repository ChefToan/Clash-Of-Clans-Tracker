// MyProfileView.swift
import SwiftUI
import AlertToast
import Lottie

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var hasInitiallyLoaded = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#1a1a2e"), Color(hex: "#0f0f1e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if let player = viewModel.player {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Offline indicator
                            if dataController.isOffline {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                        .foregroundColor(.orange)
                                    Text("Offline Mode - Showing cached data")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            PlayerHeaderView(player: player)
                            
                            LeagueInfoView(player: player)
                            
                            if player.league?.name.contains("Legend") == true {
                                TrophyChartView(playerTag: player.playerTag)
                            }
                            
                            PlayerStatsView(player: player)
                            
                            UnitProgressionView(player: player)
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        await performRefresh()
                    }
                } else if viewModel.noProfile && !viewModel.isLoading {
                    // No profile view with Lottie animation - positioned higher
                    VStack(spacing: 40) {
                        Spacer()
                            .frame(height: 20) // Much smaller top spacer to move content up
                        
                        // Lottie animation placeholder
                        LottieView(animation: .named("empty-state"))
                            .looping()
                            .frame(width: 200, height: 200)
                        
                        VStack(spacing: 10) {
                            Text("No Profile Saved")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Search for a player and save it as your profile")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 20) {
                            Button {
                                HapticManager.shared.lightImpactFeedback()
                                tabState.switchToSearch()
                            } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search Now")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Constants.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal, 40) // Match Search view horizontal padding
                        
                        Spacer() // This will take up remaining space
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Load profile when view appears if not already loaded
                if !hasInitiallyLoaded || viewModel.player == nil {
                    hasInitiallyLoaded = true
                    Task {
                        await viewModel.loadProfile()
                    }
                }
            }
            .onChange(of: tabState.selectedTab) { oldValue, newValue in
                // Reload when switching to profile tab
                if newValue == .profile && oldValue != .profile {
                    Task {
                        await viewModel.loadProfile()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ProfileDeleted"))) { _ in
                viewModel.clearProfile()
                hasInitiallyLoaded = false
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ProfileSaved"))) { notification in
                // Immediately update with the saved player data
                if let savedPlayer = notification.object as? PlayerEssentials {
                    viewModel.setPlayerData(savedPlayer)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.player == nil {
                    LoadingView()
                }
            }
            .toast(isPresenting: $isRefreshing, duration: 1) {
                AlertToast(type: .loading, title: "Refreshing...")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    HapticManager.shared.errorFeedback()
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func performRefresh() async {
        guard networkMonitor.isConnected else {
            HapticManager.shared.errorFeedback()
            return
        }
        
        isRefreshing = true
        HapticManager.shared.mediumImpactFeedback()
        
        await viewModel.refreshProfile()
        
        isRefreshing = false
        HapticManager.shared.successFeedback()
    }
}
