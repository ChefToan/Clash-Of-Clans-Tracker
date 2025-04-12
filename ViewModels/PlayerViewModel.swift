// PlayerViewModel.swift
import Foundation
import Combine
import SwiftUI

class PlayerViewModel: ObservableObject, ProgressCalculator {
    @Published var player: Player?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var rankingsData: PlayerRankings?
    @Published var isLegendLeague = false
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadPlayer(tag: String) {
        isLoading = true
        
        apiService.getPlayer(tag: tag)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }, receiveValue: { [weak self] player in
                self?.player = player
                
                // Check if in Legend League
                if let league = player.league, league.name.contains("Legend") {
                    self?.isLegendLeague = true
                    
                    // Also load rankings data
                    self?.loadPlayerRankings(tag: player.tag)
                } else {
                    self?.isLegendLeague = false
                }
            })
            .store(in: &cancellables)
    }
    
    func loadPlayerRankings(tag: String) {
        apiService.getPlayerRankings(tag: tag)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                // If there's a failure, set a default "unranked" rankings object
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
    
    // Calculate progress percentage for unit categories
    func calculateProgress(_ items: [PlayerItem]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        let totalMaxLevel = items.reduce(0) { $0 + $1.maxLevel }
        let totalCurrentLevel = items.reduce(0) { $0 + $1.level }
        
        guard totalMaxLevel > 0 else { return 0.0 }
        return Double(totalCurrentLevel) / Double(totalMaxLevel) * 100.0
    }
    
    // Helper functions for troop types
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
    
    // Format country code to flag emoji
    func countryCodeToFlag(countryCode: String) -> String {
        let base = 127397
        var flagString = ""
        
        for character in countryCode.uppercased() {
            if let scalar = UnicodeScalar(String(character).unicodeScalars.first!.value + UInt32(base)) {
                flagString.append(Character(scalar))
            }
        }
        
        return flagString
    }
    
    // Helper methods to safely get URLs
    func getClanBadgeSmallURL(_ clan: PlayerClan?) -> String? {
        return clan?.badgeUrls?.small
    }
    
    func getLeagueIconSmallURL(_ league: League?) -> String? {
        return league?.iconUrls?.small
    }
}
