import SwiftUI
import SwiftData

struct MyProfileView: View {
    @StateObject private var viewModel = MyProfileViewModel()
    @ObservedObject var tabState: TabState
    @EnvironmentObject var appState: AppState
    
    // These properties are for background refresh handling
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastRefreshTime: Date? = nil
    @State private var minimumRefreshInterval: TimeInterval = 300 // 5 minutes
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            Constants.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if viewModel.isInitialLoading || (viewModel.isLoading && viewModel.player == nil) {
                    // Only show loading indicator during initial load or when we have no profile data yet
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    Spacer()
                } else if let player = viewModel.player {
                    // Player profile content
                    ScrollView {
                        VStack(spacing: 16) {
                            PlayerProfileView(player: player)
                                .padding(.horizontal)
                                .id("profile_\(viewModel.refreshID)")
                            
                            LeagueInfoView(
                                player: player,
                                rankingsData: viewModel.rankingsData
                            )
                            .padding(.horizontal)
                            .id("league_\(viewModel.refreshID)")
                            
                            if viewModel.isLegendLeague {
                                TrophyProgressionView(player: player)
                                    .padding(.horizontal)
                                    .id("trophy_\(viewModel.refreshID)")
                            }
                            
                            PlayerStatsSection(player: player)
                                .padding(.horizontal)
                                .id("stats_\(viewModel.refreshID)")
                            
                            UnitProgressionSection(
                                player: player,
                                calculator: viewModel
                            )
                            .padding(.horizontal)
                            .id("units_\(viewModel.refreshID)")
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .id(viewModel.refreshID)
                    }
                    .refreshable {
                        if isRefreshing {
                            // Already refreshing, prevent duplicate requests
                            return
                        }
                        
                        isRefreshing = true
                        HapticManager.shared.mediumImpactFeedback()
                        
                        do {
                            try await viewModel.refreshProfile()
                            lastRefreshTime = Date()
                        } catch {
                            print("Refresh error handled in view: \(error.localizedDescription)")
                        }
                        
                        isRefreshing = false
                    }
                    // Only show loading indicator for initial load, not for refreshes
                    // Removed the overlay for pull-to-refresh operations
                } else if viewModel.noProfileConfirmed {
                    // No profile claimed view - only show when we've confirmed no profile exists
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
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            HapticManager.shared.mediumImpactFeedback()
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
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Load profile on first appear
            Task {
                await viewModel.loadProfile()
                lastRefreshTime = Date()
            }
        }
        .onChange(of: tabState.selectedTab) { _, newValue in
            // Only reload when selecting the profile tab
            if newValue == .profile {
                Task {
                    await viewModel.loadProfile()
                    lastRefreshTime = Date()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Check if enough time has passed since last refresh
                let shouldRefresh = lastRefreshTime == nil ||
                    Date().timeIntervalSince(lastRefreshTime!) > minimumRefreshInterval
                    
                if shouldRefresh {
                    Task {
                        print("Background refresh triggered - app returned to foreground")
                        try? await viewModel.refreshProfile()
                        lastRefreshTime = Date()
                    }
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
