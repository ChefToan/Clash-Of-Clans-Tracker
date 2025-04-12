// UnitSorter.swift
import Foundation

// Utility class for unit sorting
class UnitSorter {
    // Hero ordering
    static let heroOrder: [String: Int] = [
        "barbarian king": 0,
        "archer queen": 1,
        "minion prince": 2,
        "grand warden": 3,
        "royal champion": 4
    ]
    
    // Hero equipment mapping
    static let equipmentByHero: [String: [String]] = [
        "barbarian king": ["Barbarian Puppet", "Rage Vial", "Earthquake Boots", "Vampstache", "Giant Gauntlet", "Snake Bracelet", "Spiky Ball"],
        "archer queen": ["Archer Puppet", "Invisibility Vial", "Giant Arrow", "Healer Puppet", "Action Figure", "Frozen Arrow", "Magic Mirror"],
        "minion prince": ["Dark Orb", "Henchmen Puppet", "Metal Pants", "Noble Iron"],
        "grand warden": ["Eternal Tome", "Life Gem", "Healing Tome", "Rage Gem", "Lavaloon Puppet", "Fireball"],
        "royal champion": ["Royal Gem", "Seeking Shield", "Haste Vial", "Hog Rider Puppet", "Electro Boots", "Rocket Spear"]
    ]
    
    // Pet ordering
    static let petOrder: [String: Int] = [
        "L.A.S.S.I": 0,
        "Electro Owl": 1,
        "Mighty Yak": 2,
        "Unicorn": 3,
        "Frosty": 4,
        "Diggy": 5,
        "Poison Lizard": 6,
        "Spirit Fox": 7,
        "Angry Jelly": 8,
        "Sneezy": 9,
        "Phoenix": 10
    ]
    
    // Troop ordering
    static let troopOrder: [String: Int] = [
        "barbarian": 0,
        "archer": 1,
        "giant": 2,
        "goblin": 3,
        "wall breaker": 4,
        "balloon": 5,
        "wizard": 6,
        "healer": 7,
        "dragon": 8,
        "p.e.k.k.a": 9,
        "baby dragon": 10,
        "miner": 11,
        "electro dragon": 12,
        "electro titan": 13,
        "yeti": 14,
        "dragon rider": 15,
        "root rider": 16,
        "thrower": 17
    ]
    
    // Dark elixir troop ordering
    static let darkTroopOrder: [String: Int] = [
        "minion": 0,
        "hog rider": 1,
        "valkyrie": 2,
        "golem": 3,
        "witch": 4,
        "lava hound": 5,
        "bowler": 6,
        "ice golem": 7,
        "headhunter": 8,
        "apprentice warden": 9,
        "druid": 10,
        "furnace": 11
    ]
    
    // Siege machine ordering
    static let siegeOrder: [String: Int] = [
        "wall wrecker": 0,
        "battle blimp": 1,
        "stone slammer": 2,
        "siege barracks": 3,
        "log launcher": 4,
        "flame flinger": 5,
        "battle drill": 6,
        "troop launcher": 7
    ]
    
    // Spell ordering
    static let spellOrder: [String: Int] = [
        "lightning spell": 0,
        "healing spell": 1,
        "rage spell": 2,
        "jump spell": 3,
        "freeze spell": 4,
        "clone spell": 5,
        "invisibility spell": 6,
        "recall spell": 7,
        "revive spell": 8,
        "poison spell": 9,
        "earthquake spell": 10,
        "haste spell": 11,
        "skeleton spell": 12,
        "bat spell": 13,
        "overgrowth spell": 14
    ]
    
    // Known super troops
    static let superTroops = [
        "Super Barbarian", "Super Archer", "Sneaky Goblin",
        "Super Wall Breaker", "Super Giant", "Rocket Balloon",
        "Super Wizard", "Super Dragon", "Inferno Dragon",
        "Super Valkyrie", "Super Witch", "Ice Hound",
        "Super Bowler", "Super Miner", "Super Hog Rider"
    ]
    
    // In the filterAndSortItems function
    static func filterAndSortItems(_ player: Player) -> (heroes: [PlayerItem], heroEquipment: [[PlayerItem]], pets: [PlayerItem], troops: [PlayerItem], darkTroops: [PlayerItem], siegeMachines: [PlayerItem], spells: [PlayerItem]) {
        var heroes: [PlayerItem] = []
        var kingEquipment: [PlayerItem] = []
        var queenEquipment: [PlayerItem] = []
        var minionPrinceEquipment: [PlayerItem] = []
        var wardenEquipment: [PlayerItem] = []
        var championEquipment: [PlayerItem] = []
        var pets: [PlayerItem] = []
        var regularTroops: [PlayerItem] = []
        var darkTroops: [PlayerItem] = []
        var siegeMachines: [PlayerItem] = []
        var spells: [PlayerItem] = []
        
        // Process heroes
        if let playerHeroes = player.heroes?.filter({ $0.village == "home" }) {
            heroes = playerHeroes.sorted { (a, b) -> Bool in
                let orderA = heroOrder[a.name.lowercased()] ?? 999
                let orderB = heroOrder[b.name.lowercased()] ?? 999
                return orderA < orderB
            }
        }
        
        // Process hero equipment
        if let heroEquipmentItems = player.heroEquipment?.filter({ $0.village == "home" && $0.level > 0 }) {
            for item in heroEquipmentItems {
                // Assign equipment to the appropriate hero based on the equipment name
                if equipmentByHero["barbarian king"]?.contains(item.name) ?? false {
                    kingEquipment.append(item)
                } else if equipmentByHero["archer queen"]?.contains(item.name) ?? false {
                    queenEquipment.append(item)
                } else if equipmentByHero["minion prince"]?.contains(item.name) ?? false {
                    minionPrinceEquipment.append(item)
                } else if equipmentByHero["grand warden"]?.contains(item.name) ?? false {
                    wardenEquipment.append(item)
                } else if equipmentByHero["royal champion"]?.contains(item.name) ?? false {
                    championEquipment.append(item)
                }
            }
            
            // Sort equipment based on specified order
            kingEquipment.sort { (a, b) -> Bool in
                let orderA = equipmentByHero["barbarian king"]?.firstIndex(of: a.name) ?? 999
                let orderB = equipmentByHero["barbarian king"]?.firstIndex(of: b.name) ?? 999
                return orderA < orderB
            }
            
            queenEquipment.sort { (a, b) -> Bool in
                let orderA = equipmentByHero["archer queen"]?.firstIndex(of: a.name) ?? 999
                let orderB = equipmentByHero["archer queen"]?.firstIndex(of: b.name) ?? 999
                return orderA < orderB
            }
            
            minionPrinceEquipment.sort { (a, b) -> Bool in
                let orderA = equipmentByHero["minion prince"]?.firstIndex(of: a.name) ?? 999
                let orderB = equipmentByHero["minion prince"]?.firstIndex(of: b.name) ?? 999
                return orderA < orderB
            }
            
            wardenEquipment.sort { (a, b) -> Bool in
                let orderA = equipmentByHero["grand warden"]?.firstIndex(of: a.name) ?? 999
                let orderB = equipmentByHero["grand warden"]?.firstIndex(of: b.name) ?? 999
                return orderA < orderB
            }
            
            championEquipment.sort { (a, b) -> Bool in
                let orderA = equipmentByHero["royal champion"]?.firstIndex(of: a.name) ?? 999
                let orderB = equipmentByHero["royal champion"]?.firstIndex(of: b.name) ?? 999
                return orderA < orderB
            }
        }
        
        // Process troops
        if let troops = player.troops {
            // Find all pets first (filter out any with level 0)
            let petNames = [
                "L.A.S.S.I", "Electro Owl", "Mighty Yak", "Unicorn",
                "Phoenix", "Poison Lizard", "Diggy", "Frosty",
                "Spirit Fox", "Angry Jelly", "Sneezy"
            ]
            
            // Extract pets and filter out any level 0 pets
            pets = troops.filter { troop in
                return petNames.contains(troop.name) && troop.level > 0
            }.sorted { (a, b) -> Bool in
                let petIndex1 = petNames.firstIndex(of: a.name) ?? 999
                let petIndex2 = petNames.firstIndex(of: b.name) ?? 999
                return petIndex1 < petIndex2
            }
            
            // Filter out super troops first
            let nonSuperTroops = troops.filter { troop in
                return !isSuperTroop(troop) && troop.level > 0 && troop.village == "home"
            }
            
            // Get remaining home village troops (excluding pets)
            let remainingTroops = nonSuperTroops.filter {
                !petNames.contains($0.name)
            }
            
            // Dark elixir troops
            darkTroops = remainingTroops.filter { isDarkElixirTroop($0) }.sorted { (a, b) -> Bool in
                let orderA = darkTroopOrder[a.name.lowercased()] ?? 999
                let orderB = darkTroopOrder[b.name.lowercased()] ?? 999
                return orderA < orderB
            }
            
            // Siege machines
            siegeMachines = remainingTroops.filter { isSiegeMachine($0) }.sorted { (a, b) -> Bool in
                let orderA = siegeOrder[a.name.lowercased()] ?? 999
                let orderB = siegeOrder[b.name.lowercased()] ?? 999
                return orderA < orderB
            }
            
            // Regular troops (exclude dark elixir, siege machines, and pets)
            regularTroops = remainingTroops.filter {
                !isDarkElixirTroop($0) && !isSiegeMachine($0)
            }.sorted { (a, b) -> Bool in
                let orderA = troopOrder[a.name.lowercased()] ?? 999
                let orderB = troopOrder[b.name.lowercased()] ?? 999
                return orderA < orderB
            }
        }
        
        // Process spells and filter out any with level 0
        if let playerSpells = player.spells?.filter({ $0.village == "home" && $0.level > 0 }) {
            spells = playerSpells.sorted { (a, b) -> Bool in
                let orderA = spellOrder[a.name.lowercased()] ?? 999
                let orderB = spellOrder[b.name.lowercased()] ?? 999
                return orderA < orderB
            }
        }
        
        // Return all categories
        let allHeroEquipment = [kingEquipment, queenEquipment, minionPrinceEquipment, wardenEquipment, championEquipment]
        return (heroes, allHeroEquipment, pets, regularTroops, darkTroops, siegeMachines, spells)
    }
    
    // Helper functions
    static func isDarkElixirTroop(_ item: PlayerItem) -> Bool {
        return darkTroopOrder.keys.contains { item.name.lowercased().contains($0) }
    }
    
    static func isSiegeMachine(_ item: PlayerItem) -> Bool {
        return siegeOrder.keys.contains { item.name.lowercased().contains($0) }
    }
    
    static func isPet(_ item: PlayerItem) -> Bool {
        return petOrder.keys.contains { item.name.lowercased().contains($0) }
    }
    
    static func isSuperTroop(_ item: PlayerItem) -> Bool {
        return superTroops.contains(item.name) ||
               item.name.contains("Super") ||
               item.superTroopIsActive == true ||
               item.name == "Sneaky Goblin" ||
               item.name == "Rocket Balloon" ||
               item.name == "Inferno Dragon" ||
               item.name == "Ice Hound"
    }
}
