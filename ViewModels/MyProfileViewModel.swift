// MyProfileViewModel.swift - with improved data handling
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
    
    // New properties for caching
    private var lastRefreshTime: Date?
    private var isInitialLoad = true
    private var forceRefresh = false
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for profile updates and removal notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileUpdated),
            name: Notification.Name("ProfileUpdated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileRemoved),
            name: Notification.Name("ProfileRemoved"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleProfileUpdated() {
        // Force reload on profile update
        DispatchQueue.main.async {
            self.forceRefresh = true
            
            // Reload profile after a small delay
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await self.loadProfile()
            }
        }
    }
    
    @objc private func handleProfileRemoved() {
        // Clear cached data and force a refresh
        DispatchQueue.main.async {
            self.player = nil
            self.rankingsData = nil
            self.isLegendLeague = false
            self.lastRefreshTime = nil
            self.isInitialLoad = true
            self.forceRefresh = true
            
            // Reload profile after a small delay
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await self.loadProfile()
            }
        }
    }
    
    nonisolated func calculateProgress(_ items: [PlayerItem]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        let totalMaxLevel = items.reduce(0) { $0 + $1.maxLevel }
        let totalCurrentLevel = items.reduce(0) { $0 + $1.level }
        
        guard totalMaxLevel > 0 else { return 0.0 }
        return Double(totalCurrentLevel) / Double(totalMaxLevel) * 100.0
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
        // Show loading indicator on initial load or force refresh
        if isInitialLoad || forceRefresh {
            isLoading = true
            
            if forceRefresh {
                // Clear any cached data when forcing a refresh
                self.player = nil
            }
        }
        
        // Check if we have a cached profile, it's not the initial load, and we're not forcing a refresh
        if !isInitialLoad && !forceRefresh && player != nil {
            // Use the cached profile
            isLoading = false
            return
        }
        
        // Reset force refresh flag
        forceRefresh = false
        
        // Load profile from database with full unit data
        let savedPlayer = await DataController.shared.getMyProfile()
        if let player = savedPlayer {
            // Check if the player has unit progression data
            let hasTroops = player.troops != nil && !player.troops!.isEmpty
            let hasHeroes = player.heroes != nil && !player.heroes!.isEmpty
            let hasSpells = player.spells != nil && !player.spells!.isEmpty
            
            // Update profile state with the loaded player data
            updateProfileState(player)
            
            // If missing unit data, fetch it from the API
            if !hasTroops || !hasHeroes || !hasSpells {
                print("Profile is missing unit data, refreshing from API")
                await refreshProfile(forceUnitRefresh: true)
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
        
        // Update initial load flag
        isInitialLoad = false
    }
    
    private func updateProfileState(_ player: Player) {
        self.player = player
        
        // Check if in Legend League
        if let league = player.league, league.name.contains("Legend") {
            isLegendLeague = true
            loadRankingsData(tag: player.tag)
        } else {
            isLegendLeague = false
            rankingsData = nil
        }
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
    
    func refreshProfile(forceUnitRefresh: Bool = false) async {
        guard let currentPlayer = player else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            let updatedPlayer = try await apiService.getPlayerAsync(tag: currentPlayer.tag)
            
            // Update the view model with the fresh data
            self.player = updatedPlayer
            updateProfileState(updatedPlayer)
            
            // Save the updated player to SwiftData with force reload if needed
            let saveResult = await DataController.shared.savePlayer(updatedPlayer, forceReload: forceUnitRefresh)
            if !saveResult {
                self.errorMessage = "Failed to save profile to database"
                self.showError = true
            }
            
            // Update last refresh time
            lastRefreshTime = Date()
            
        } catch {
            self.errorMessage = "Failed to refresh profile: \(error.localizedDescription)"
            self.showError = true
        }
        
        isLoading = false
    }
    
    // Explicitly check if a profile exists in the database
    func checkIfProfileExists() async -> Bool {
        return await DataController.shared.hasMyProfile()
    }
}
