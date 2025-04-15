// DataController.swift
import Foundation
import SwiftData
import SwiftUI

@MainActor
class DataController: ObservableObject {
    static let shared = DataController()
    private var container: ModelContainer?
    
    // Get ModelContainer for the app
    func getModelContainer() -> ModelContainer {
        if let container = container {
            return container
        }
        
        do {
            let schema = Schema([PlayerModel.self])
            let config = ModelConfiguration("ClashOfClansTracker", schema: schema)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // Save player to SwiftData
    func savePlayer(_ player: Player) async -> Bool {
        do {
            let modelContext = getModelContainer().mainContext
            
            // Use native SwiftData predicate
            let descriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.tag == player.tag
                }
            )
            
            let existingPlayers = try modelContext.fetch(descriptor)
            
            let playerModel: PlayerModel
            
            if let existingPlayer = existingPlayers.first {
                playerModel = existingPlayer
            } else {
                playerModel = PlayerModel(
                    tag: player.tag,
                    name: player.name,
                    expLevel: player.expLevel,
                    trophies: player.trophies,
                    bestTrophies: player.bestTrophies,
                    attackWins: player.attackWins,
                    defenseWins: player.defenseWins,
                    townHallLevel: player.townHallLevel,
                    warStars: player.warStars,
                    donations: player.donations,
                    donationsReceived: player.donationsReceived,
                    clanCapitalContributions: player.clanCapitalContributions
                )
                modelContext.insert(playerModel)
            }
            
            // Update properties
            playerModel.name = player.name
            playerModel.expLevel = player.expLevel
            playerModel.trophies = player.trophies
            playerModel.bestTrophies = player.bestTrophies
            playerModel.attackWins = player.attackWins
            playerModel.defenseWins = player.defenseWins
            playerModel.townHallLevel = player.townHallLevel
            playerModel.warStars = player.warStars
            playerModel.donations = player.donations
            playerModel.donationsReceived = player.donationsReceived
            playerModel.clanCapitalContributions = player.clanCapitalContributions
            
            if let builderHallLevel = player.builderHallLevel {
                playerModel.builderHallLevel = builderHallLevel
            }
            
            if let builderBaseTrophies = player.builderBaseTrophies {
                playerModel.builderBaseTrophies = builderBaseTrophies
            }
            
            if let bestBuilderBaseTrophies = player.bestBuilderBaseTrophies {
                playerModel.bestBuilderBaseTrophies = bestBuilderBaseTrophies
            }
            
            // JSON encoding for complex objects
            if let clan = player.clan {
                let jsonEncoder = JSONEncoder()
                if let clanData = try? jsonEncoder.encode(clan) {
                    playerModel.clanData = clanData
                }
            }
            
            if let league = player.league {
                let jsonEncoder = JSONEncoder()
                if let leagueData = try? jsonEncoder.encode(league) {
                    playerModel.leagueData = leagueData
                }
            }
            
            // Set as my profile
            playerModel.isMyProfile = true
            
            // Clear isMyProfile for all other players
            let allPlayersDescriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.tag != player.tag
                }
            )
            
            let allOtherPlayers = try modelContext.fetch(allPlayersDescriptor)
            
            for otherPlayer in allOtherPlayers {
                otherPlayer.isMyProfile = false
            }
            
            try modelContext.save()
            
            // Update UserDefaults to indicate a profile has been claimed
            UserDefaults.standard.set(true, forKey: "hasClaimedProfile")
            
            return true
        } catch {
            print("Failed to save player: \(error)")
            return false
        }
    }
    
    // Check if a MyProfile record exists in the database
    func hasMyProfile() async -> Bool {
        do {
            let modelContext = getModelContainer().mainContext
            
            // Use native SwiftData predicate to find any profile marked as "my profile"
            let descriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.isMyProfile == true
                }
            )
            
            // Set fetch limit in a separate step to fix the argument error
            var limitedDescriptor = descriptor
            limitedDescriptor.fetchLimit = 1
            
            let results = try modelContext.fetch(limitedDescriptor)
            return !results.isEmpty
        } catch {
            print("Failed to check for my profile: \(error)")
            return false
        }
    }
    
    // Get my profile player from SwiftData
    func getMyProfile() async -> Player? {
        do {
            let modelContext = getModelContainer().mainContext
            
            // Use native SwiftData predicate
            let descriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.isMyProfile == true
                }
            )
            
            let results = try modelContext.fetch(descriptor)
            
            if let playerModel = results.first {
                return convertToPlayer(playerModel)
            }
        } catch {
            print("Failed to fetch my profile: \(error)")
        }
        
        return nil
    }
    
    // Convert PlayerModel to Player
    private func convertToPlayer(_ model: PlayerModel) -> Player {
        var clan: PlayerClan?
        if let clanData = model.clanData {
            let jsonDecoder = JSONDecoder()
            clan = try? jsonDecoder.decode(PlayerClan.self, from: clanData)
        }
        
        var league: League?
        if let leagueData = model.leagueData {
            let jsonDecoder = JSONDecoder()
            league = try? jsonDecoder.decode(League.self, from: leagueData)
        }
        
        // Create a basic Player object with essential data
        return Player(
            tag: model.tag,
            name: model.name,
            expLevel: model.expLevel,
            trophies: model.trophies,
            bestTrophies: model.bestTrophies,
            donations: model.donations,
            donationsReceived: model.donationsReceived,
            attackWins: model.attackWins,
            defenseWins: model.defenseWins,
            townHallLevel: model.townHallLevel,
            townHallWeaponLevel: nil,
            warStars: model.warStars,
            clanCapitalContributions: model.clanCapitalContributions,
            clan: clan,
            league: league,
            troops: [],
            heroes: [],
            spells: [],
            heroEquipment: [],
            role: nil,
            builderHallLevel: model.builderHallLevel,
            builderBaseTrophies: model.builderBaseTrophies,
            bestBuilderBaseTrophies: model.bestBuilderBaseTrophies,
            legends: nil
        )
    }
    
    // Remove my profile
    func removeMyProfile() async -> Bool {
        do {
            let modelContext = getModelContainer().mainContext
            
            // Find any profile marked as my profile
            let descriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.isMyProfile == true
                }
            )
            
            let results = try modelContext.fetch(descriptor)
            print("Found \(results.count) profiles marked as 'my profile'")
            
            // Delete any found profiles
            for profile in results {
                print("Deleting profile: \(profile.name) (\(profile.tag))")
                modelContext.delete(profile)
            }
            
            // Save changes to the database
            try modelContext.save()
            
            // Verify the deletion
            let verifyDescriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.isMyProfile == true
                }
            )
            
            let verifyResults = try modelContext.fetch(verifyDescriptor)
            print("After deletion: \(verifyResults.count) profiles marked as 'my profile'")
            
            // Update UserDefaults
            UserDefaults.standard.set(false, forKey: "hasClaimedProfile")
            
            return true
        } catch {
            print("Failed to remove my profile: \(error)")
            return false
        }
    }
    
    // Clear all data in SwiftData store
    func clearAllData() async {
        do {
            let modelContext = getModelContainer().mainContext
            
            // Fetch all player models
            let descriptor = FetchDescriptor<PlayerModel>()
            let allPlayers = try modelContext.fetch(descriptor)
            
            // Delete all players
            for player in allPlayers {
                modelContext.delete(player)
            }
            
            try modelContext.save()
            
            // Reset UserDefaults key for profile
            UserDefaults.standard.set(false, forKey: "hasClaimedProfile")
            
            print("Successfully cleared all data from SwiftData store")
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}
