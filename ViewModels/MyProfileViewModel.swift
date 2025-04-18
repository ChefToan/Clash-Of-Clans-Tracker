// MyProfileViewModel.swift
import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
class MyProfileViewModel: ObservableObject, ProgressCalculator {
    @Published var player: Player?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isLegendLeague = false
    @Published var rankingsData: PlayerRankings?
    
    // Keep these properties but they're not displayed in the UI
    private var nextRefreshTime: String = ""
    private var isAutoRefreshEnabled: Bool = false
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private let refreshScheduler = RefreshScheduler.shared
    
    nonisolated func calculateProgress(_ items: [PlayerItem]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        let totalMaxLevel = items.reduce(0) { $0 + $1.maxLevel }
        let totalCurrentLevel = items.reduce(0) { $0 + $1.level }
        
        guard totalMaxLevel > 0 else { return 0.0 }
        return Double(totalCurrentLevel) / Double(totalMaxLevel) * 100.0
    }
    
    func setupAutoRefresh() {
        // Get auto-refresh setting
        isAutoRefreshEnabled = UserDefaults.standard.bool(forKey: "autoRefresh")
        
        // Update next refresh time
        updateNextRefreshTimeDisplay()
        
        // Schedule refresh if enabled
        if isAutoRefreshEnabled {
            scheduleAutoRefresh()
        }
        
        // Listen for setting changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AutoRefreshSettingChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isAutoRefreshEnabled = UserDefaults.standard.bool(forKey: "autoRefresh")
            if self?.isAutoRefreshEnabled == true {
                self?.scheduleAutoRefresh()
            }
        }
    }
    
    private func updateNextRefreshTimeDisplay() {
        nextRefreshTime = refreshScheduler.formatNextResetTime()
    }
    
    private func scheduleAutoRefresh() {
        refreshScheduler.scheduleNextRefresh { [weak self] in
            Task {
                await self?.performAutoRefresh()
            }
        }
    }
    
    private func performAutoRefresh() async {
        if refreshScheduler.shouldRefresh() {
            await refreshProfile()
            refreshScheduler.updateLastRefreshTime()
        }
        
        updateNextRefreshTimeDisplay()
    }
    
    func isSuperTroop(_ item: PlayerItem) -> Bool {
        return item.name.contains("Super") || (item.superTroopIsActive == true)
    }
    
    func isDarkElixirTroop(_ item: PlayerItem) -> Bool {
        let darkTroopNames = [
            "Minion", "Hog", "Valkyrie", "Golem", "Witch",
            "Lava", "Bowler", "Ice Golem", "Headhunter"
        ]
        
        return darkTroopNames.contains { item.name.contains($0) }
    }
    
    func isSiegeMachine(_ item: PlayerItem) -> Bool {
        return item.name.contains("Wall Wrecker") ||
               item.name.contains("Battle Blimp") ||
               item.name.contains("Stone Slammer") ||
               item.name.contains("Siege Barracks") ||
               item.name.contains("Log Launcher") ||
               item.name.contains("Flame Flinger") ||
               item.name.contains("Battle Drill")
    }
    
    func loadProfile() async {
        isLoading = true
        self.player = nil  // Reset player immediately to avoid stale data
        
        // Check if auto-refresh should happen
        if refreshScheduler.shouldRefresh() {
            print("Auto refresh triggered on profile load")
            // Loading profile with refresh
            let savedPlayer = await DataController.shared.getMyProfile()
            if let player = savedPlayer {
                // Load profile and then refresh
                self.player = player
                await refreshProfile()
                refreshScheduler.updateLastRefreshTime()
            } else {
                // No profile to refresh
                self.player = nil
                isLegendLeague = false
                rankingsData = nil
                isLoading = false
            }
        } else {
            // Regular profile load without refresh
            let savedPlayer = await DataController.shared.getMyProfile()
            if let player = savedPlayer {
                self.player = player
                
                // Check if in Legend League
                if let league = player.league, league.name.contains("Legend") {
                    isLegendLeague = true
                    loadRankingsData(tag: player.tag)
                } else {
                    isLegendLeague = false
                    rankingsData = nil
                }
                
                // If the saved player has no troop data, try to refresh from API
                if player.troops == nil || player.troops?.isEmpty == true {
                    print("No troop data found, refreshing from API")
                    await refreshProfile()
                } else {
                    isLoading = false
                }
            } else {
                // No profile found
                self.player = nil
                isLegendLeague = false
                rankingsData = nil
                isLoading = false
            }
        }
        
        // Still update the refresh time internally
        updateNextRefreshTimeDisplay()
    }
    
    func loadRankingsData(tag: String) {
        apiService.getPlayerRankings(tag: tag)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.rankingsData = PlayerRankings(
                        tag: tag,
                        countryCode: "US",
                        countryName: "United States",
                        localRank: nil,
                        builderGlobalRank: nil,
                        builderLocalRank: nil,
                        globalRank: nil,
                        streak: 0
                    )
                }
            }, receiveValue: { [weak self] rankings in
                self?.rankingsData = rankings
            })
            .store(in: &cancellables)
    }
    
    func refreshProfile() async {
        guard let currentPlayer = player else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            let updatedPlayer = try await apiService.getPlayerAsync(tag: currentPlayer.tag)
            
            self.player = updatedPlayer
            
            // Check if in Legend League
            if let league = updatedPlayer.league, league.name.contains("Legend") {
                self.isLegendLeague = true
                loadRankingsData(tag: updatedPlayer.tag)
            } else {
                self.isLegendLeague = false
                self.rankingsData = nil
            }
            
            // Save updated profile to SwiftData and handle the result
            let saveResult = await DataController.shared.savePlayer(updatedPlayer)
            if !saveResult {
                self.errorMessage = "Failed to save profile to database"
                self.showError = true
            }
            
        } catch {
            self.errorMessage = "Failed to refresh profile: \(error.localizedDescription)"
            self.showError = true
        }
        
        isLoading = false
        updateNextRefreshTimeDisplay()
    }
    
    // Explicitly check if a profile exists in the database
    func checkIfProfileExists() async -> Bool {
        return await DataController.shared.hasMyProfile()
    }
}
