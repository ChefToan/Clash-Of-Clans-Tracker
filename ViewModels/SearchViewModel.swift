// SearchViewModel.swift
import Foundation
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchTag = ""
    @Published var isLoading = false
    @Published var player: PlayerEssentials?
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    
    private let apiService = APIService.shared
    
    func searchPlayer() async {
        guard !searchTag.isEmpty else {
            errorMessage = "Please enter a player tag"
            showError = true
            HapticManager.shared.errorFeedback()
            return
        }
        
        isLoading = true
        errorMessage = nil
        player = nil
        
        do {
            let player = try await apiService.getPlayerEssentials(tag: searchTag)
            self.player = player
            HapticManager.shared.successFeedback()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.errorFeedback()
        }
        
        isLoading = false
    }
    
    func saveAsProfile() async -> Bool {
        guard let player = player else { return false }
        
        isLoading = true
        
        do {
            // Save the profile
            try await DataController.shared.saveProfile(player)
            
            // Verify the save was successful
            if let savedPlayer = try await DataController.shared.getProfile() {
                // Post notification with the saved player data
                NotificationCenter.default.post(
                    name: Notification.Name("ProfileSaved"),
                    object: savedPlayer
                )
                
                showSuccess = true
                HapticManager.shared.successFeedback()
                
                // Clear search state after a delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                self.showSuccess = false
                
                isLoading = false
                return true
            } else {
                throw APIError.decodingError
            }
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.errorFeedback()
            isLoading = false
            return false
        }
    }
    
    func refreshPlayer() async {
        guard let currentPlayer = player else { return }
        
        isLoading = true
        
        do {
            let refreshed = try await apiService.refreshPlayerEssentials(tag: currentPlayer.playerTag)
            self.player = refreshed
            HapticManager.shared.successFeedback()
        } catch {
            errorMessage = "Failed to refresh: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.errorFeedback()
        }
        
        isLoading = false
    }
    
    // Clear just the current player, not the search tag
    func clearCurrentSearch() {
        player = nil
        errorMessage = nil
        showError = false
        showSuccess = false
        // Keep searchTag so user can modify their search
    }
    
    // Clear everything for a fresh search
    func clearAll() {
        searchTag = ""
        player = nil
        errorMessage = nil
        showError = false
        showSuccess = false
    }
}
