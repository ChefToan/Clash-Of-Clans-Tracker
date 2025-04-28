import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
class MyProfileViewModel: ObservableObject, ProgressCalculator {
    @Published var player: Player?
    @Published var isLoading = true
    @Published var isInitialLoading = true
    @Published var isRefreshLoading = false // Separate state for refresh operations
    @Published var noProfileConfirmed = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isLegendLeague = false
    @Published var rankingsData: PlayerRankings?
    @Published var refreshID = UUID()
    @Published var isDataComplete = false // New flag to track when data is fully loaded
    
    private var lastRefreshTime: Date?
    private var forceRefresh = false
    private var isRefreshInProgress = false
    
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
            self.forceRefresh = true
            self.isDataComplete = false
            
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
        // Start with loading state
        isInitialLoading = true
        isLoading = true
        isDataComplete = false // Reset completion flag
        noProfileConfirmed = false // Reset this flag
        
        // Check if profile exists first - quick check to determine state
        let profileExists = await DataController.shared.hasMyProfile()
        
        if !profileExists {
            // We've confirmed no profile exists
            self.player = nil
            isLegendLeague = false
            rankingsData = nil
            noProfileConfirmed = true
            isLoading = false
            isInitialLoading = false
            return
        }
        
        // If a profile exists, always try to get fresh data from API first
        if let savedPlayer = await DataController.shared.getMyProfile() {
            // First update with local data to show something immediately
            updateProfileState(savedPlayer)
            
            // Then try to get fresh data from API for best accuracy
            do {
                // Try to get updated player data with complete info
                if let updatedPlayer = try? await refreshFromAPI(tag: savedPlayer.tag) {
                    // Update with fresh data from API
                    updateProfileState(updatedPlayer)
                    
                    // Save back to database
                    _ = await DataController.shared.savePlayer(updatedPlayer, forceReload: false)
                }
            } catch {
                print("Could not refresh from API, using local data: \(error)")
                // We already loaded local data, so it's okay
            }
            
            // Set data complete flag after a short delay to ensure UI updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isDataComplete = true
                self.refreshID = UUID() // Force UI refresh
            }
        } else {
            // Profile should exist but we couldn't get it
            self.player = nil
            isLegendLeague = false
            rankingsData = nil
            noProfileConfirmed = true
        }
        
        // Update loading state
        isLoading = false
        isInitialLoading = false
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
    
    // New simpler method specifically for API refreshes
    private func refreshFromAPI(tag: String) async throws -> Player? {
        // Set a maximum timeout
        let timeout: TimeInterval = 10 // Reduced to 10 seconds
        
        // Create a task for the API request
        let apiTask = Task { () -> Player in
            try await apiService.getPlayerAsync(tag: tag)
        }
        
        // Create a task for the timeout
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            apiTask.cancel()
            throw NSError(domain: "RefreshTimeout", code: 1, userInfo: [NSLocalizedDescriptionKey: "Refresh timed out"])
        }
        
        do {
            // Wait for the API task to complete
            let result = try await apiTask.value
            // Cancel the timeout task
            timeoutTask.cancel()
            return result
        } catch {
            // Cancel the timeout task if it hasn't completed yet
            timeoutTask.cancel()
            throw error
        }
    }
    
    // Public refresh method - now throws errors
    func refreshProfile() async throws {
        guard let currentPlayer = player else {
            isRefreshLoading = false
            throw NSError(domain: "RefreshProfile", code: 0, userInfo: [NSLocalizedDescriptionKey: "No player data available"])
        }
        
        // Prevent multiple simultaneous refresh operations
        if isRefreshInProgress {
            throw NSError(domain: "RefreshProfile", code: 2, userInfo: [NSLocalizedDescriptionKey: "Refresh already in progress"])
        }
        
        isRefreshInProgress = true
        isRefreshLoading = true // Use this instead of isLoading
        
        do {
            // Simple approach - just try to get the player data with a reasonable timeout
            if let updatedPlayer = try await refreshFromAPI(tag: currentPlayer.tag) {
                // Update the view model with the fresh data
                self.player = updatedPlayer
                updateProfileState(updatedPlayer)
                
                // Save to database
                let saveResult = await DataController.shared.savePlayer(updatedPlayer, forceReload: false)
                if !saveResult {
                    print("Failed to save profile to database")
                }
                
                // Force view refresh and mark data as complete
                refreshID = UUID()
                isDataComplete = true
            }
        } catch is CancellationError {
            // Handle cancellation specifically
            print("Refresh operation was cancelled")
            self.errorMessage = "Unable to connect to server"
            self.showError = true
            throw NSError(domain: "RefreshProfile", code: 3, userInfo: [NSLocalizedDescriptionKey: "Refresh operation was cancelled"])
        } catch let error as NSError where error.domain == "RefreshTimeout" {
            // Handle timeout
            print("Refresh operation timed out")
            self.errorMessage = "Refresh timed out, please try again"
            self.showError = true
            throw error
        } catch {
            // Handle other errors
            print("Failed to refresh profile: \(error.localizedDescription)")
            self.errorMessage = "Failed to refresh profile: \(error.localizedDescription)"
            self.showError = true
            throw error
        }
        
        // Clean up regardless of success/failure
        isRefreshLoading = false
        isRefreshInProgress = false
    }
    
    // Explicitly check if a profile exists in the database
    func checkIfProfileExists() async -> Bool {
        return await DataController.shared.hasMyProfile()
    }
}
