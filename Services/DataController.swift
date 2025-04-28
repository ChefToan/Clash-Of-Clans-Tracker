// DataController.swift - with improved player data saving
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
    
    @MainActor
    func refreshMyProfileData() async -> Bool {
        do {
            let modelContext = getModelContainer().mainContext
            
            // Find the "my profile" record
            let descriptor = FetchDescriptor<PlayerModel>(
                predicate: #Predicate<PlayerModel> { model in
                    model.isMyProfile == true
                }
            )
            
            let results = try modelContext.fetch(descriptor)
            
            if let playerModel = results.first {
                // Get the player's tag
                let tag = playerModel.tag
                
                // Use the API service to get updated player data
                let apiService = APIService()
                let updatedPlayer = try await apiService.getPlayerAsync(tag: tag)
                
                // Save the updated player to SwiftData
                return await savePlayer(updatedPlayer, forceReload: true)
            }
            
            return false
        } catch {
            print("Failed to refresh profile data: \(error)")
            return false
        }
    }
    
    // Save player to SwiftData with improved data handling
    func savePlayer(_ player: Player, forceReload: Bool = false) async -> Bool {
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
            
            // Store troops, heroes, spells data
            let jsonEncoder = JSONEncoder()
            
            if let troops = player.troops, !troops.isEmpty {
                if let troopsData = try? jsonEncoder.encode(troops) {
                    playerModel.troopsData = troopsData
                }
            }
            
            if let heroes = player.heroes, !heroes.isEmpty {
                if let heroesData = try? jsonEncoder.encode(heroes) {
                    playerModel.heroesData = heroesData
                }
            }
            
            if let spells = player.spells, !spells.isEmpty {
                if let spellsData = try? jsonEncoder.encode(spells) {
                    playerModel.spellsData = spellsData
                }
            }
            
            if let heroEquipment = player.heroEquipment, !heroEquipment.isEmpty {
                if let equipData = try? jsonEncoder.encode(heroEquipment) {
                    playerModel.heroEquipmentData = equipData
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
            
            // Notify of profile update for proper refreshing of data
            if forceReload {
                NotificationCenter.default.post(name: Notification.Name("ProfileUpdated"), object: nil)
            }
            
            return true
        } catch {
            print("Failed to save player: \(error)")
            return false
        }
    }
    
    // Convert PlayerModel to Player with full data
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
        
        // Decode additional stored data
        let jsonDecoder = JSONDecoder()
        
        var troops: [PlayerItem]? = nil
        if let troopsData = model.troopsData {
            troops = try? jsonDecoder.decode([PlayerItem].self, from: troopsData)
        }
        
        var heroes: [PlayerItem]? = nil
        if let heroesData = model.heroesData {
            heroes = try? jsonDecoder.decode([PlayerItem].self, from: heroesData)
        }
        
        var spells: [PlayerItem]? = nil
        if let spellsData = model.spellsData {
            spells = try? jsonDecoder.decode([PlayerItem].self, from: spellsData)
        }
        
        var heroEquipment: [PlayerItem]? = nil
        if let equipData = model.heroEquipmentData {
            heroEquipment = try? jsonDecoder.decode([PlayerItem].self, from: equipData)
        }
        
        // Create a complete Player object with all available data
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
            troops: troops,
            heroes: heroes,
            spells: spells,
            heroEquipment: heroEquipment,
            role: nil,
            builderHallLevel: model.builderHallLevel,
            builderBaseTrophies: model.builderBaseTrophies,
            bestBuilderBaseTrophies: model.bestBuilderBaseTrophies,
            legends: nil
        )
    }
    
    // Get my profile player from SwiftData with complete data
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
                let player = convertToPlayer(playerModel)
                
                // If missing progression data, try to reload from API
                if (player.troops == nil || player.troops?.isEmpty == true) &&
                   (player.heroes == nil || player.heroes?.isEmpty == true) &&
                   (player.spells == nil || player.spells?.isEmpty == true) {
                    
                    print("Missing progression data, attempting to refresh from API")
                    // Try to refresh data from API
                    let apiService = APIService()
                    do {
                        let updatedPlayer = try await apiService.getPlayerAsync(tag: player.tag)
                        // Save back to database with force reload
                        _ = await savePlayer(updatedPlayer, forceReload: true)
                        return updatedPlayer
                    } catch {
                        print("Failed to refresh from API: \(error)")
                        return player
                    }
                }
                
                return player
            }
        } catch {
            print("Failed to fetch my profile: \(error)")
        }
        
        return nil
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
