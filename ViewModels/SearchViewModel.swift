// SearchViewModel.swift
import Foundation
import Combine
import SwiftUI
import SwiftData

class SearchViewModel: ObservableObject {
    @Published var playerTag = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var player: Player?
    @Published var showTimezoneSelection = false
    @Published var showPlayerStats = false
    @Published var showSuccess = false
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Try to load last searched player on initialization
//        loadLastSearchedPlayer()
    }
    
    func searchPlayer() {
        // Ensure player tag has # prefix
        var formattedTag = playerTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add # if it doesn't exist
        if !formattedTag.hasPrefix("#") {
            formattedTag = "#\(formattedTag)"
        }
        
        // Validate player tag
        guard !formattedTag.isEmpty else {
            errorMessage = "Please enter a player tag"
            showError = true
            return
        }
        
        isLoading = true
        
        apiService.getPlayer(tag: formattedTag)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }, receiveValue: { [weak self] player in
                self?.player = player
                
                // Show player stats directly (new flow)
                self?.showPlayerStats = true
                
                // Save player to UserDefaults to allow state persistence
                self?.saveLastSearchedPlayer(player)
            })
            .store(in: &cancellables)
    }
    
    @MainActor
    func refreshPlayerData() async {
        guard let player = player else { return }
        
//        isLoading = true
        
        do {
            // Create a new Task with explicit error handling for cancellation
            let updatedPlayer = try await Task.detached {
                do {
                    return try await self.apiService.getPlayerAsync(tag: player.tag)
                } catch is CancellationError {
                    // Handle cancellation gracefully
                    throw NSError(
                        domain: "SearchViewModel",
                        code: -999,
                        userInfo: [NSLocalizedDescriptionKey: "Refresh operation was cancelled"]
                    )
                } catch {
                    throw error
                }
            }.value
            
            // Update the player property with the new data
            self.player = updatedPlayer
            
            // Save the updated player to UserDefaults to maintain state
            saveLastSearchedPlayer(updatedPlayer)
            
        } catch is CancellationError {
            // Handle Task cancellation specifically
            errorMessage = "Refresh operation was cancelled"
            showError = true
        } catch {
            // Handle other errors
            errorMessage = "Failed to refresh: \(error.localizedDescription)"
            showError = true
        }
        
//        isLoading = false
    }
    
    @MainActor
    func saveProfile(_ player: Player) async {
        // Show timezone selection when adding to My Profile
        showTimezoneSelection = true
        showPlayerStats = false
    }

    @MainActor
    func completeProfileSave(_ player: Player) async {
        // Save the player profile and check result
        let saveSuccess = await DataController.shared.savePlayer(player)
        
        if saveSuccess {
            // Display success message
            showSuccess = true
            
            // Reset view to search state after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.resetToSearchState()
                
                // Clear the saved player since we added it to My Profile
                UserDefaults.standard.removeObject(forKey: "lastSearchedPlayer")
            }
        } else {
            // Handle save failure
            errorMessage = "Failed to save player profile"
            showError = true
        }
    }
    
    func resetToSearchState() {
        playerTag = ""
        player = nil
        showTimezoneSelection = false
        showPlayerStats = false
        showSuccess = false
        
        // Clear the saved player when explicitly returning to search
        UserDefaults.standard.removeObject(forKey: "lastSearchedPlayer")
    }
    
    // Save last searched player to maintain state when switching tabs
    private func saveLastSearchedPlayer(_ player: Player) {
        // Encode player to JSON
        do {
            let encoder = JSONEncoder()
            let playerData = try encoder.encode(player)
            UserDefaults.standard.set(playerData, forKey: "lastSearchedPlayer")
            UserDefaults.standard.set(Date(), forKey: "lastSearchTimestamp")
        } catch {
            print("Failed to save player to UserDefaults: \(error)")
        }
    }
    
    // Load last searched player when returning to tab
    private func loadLastSearchedPlayer() {
        // Check if we have a saved player and it's not too old (less than 1 hour)
        if let playerData = UserDefaults.standard.data(forKey: "lastSearchedPlayer"),
           let savedTimestamp = UserDefaults.standard.object(forKey: "lastSearchTimestamp") as? Date,
           Date().timeIntervalSince(savedTimestamp) < 3600 { // 1 hour
            
            do {
                let decoder = JSONDecoder()
                let savedPlayer = try decoder.decode(Player.self, from: playerData)
                
                // Restore state and show player stats
                self.player = savedPlayer
                self.playerTag = savedPlayer.tag
                self.showPlayerStats = true
            } catch {
                print("Failed to load player from UserDefaults: \(error)")
            }
        }
    }
}
