//  ItemView.swift
import SwiftUI

struct ItemView: View {
    let item: PlayerItem
    @State private var showDebug = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            // Unit icon at the top
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(Constants.innerCornerRadius/2)
                
                // Icon image from assets
                if let unitImage = UIImage(named: getUnitImageName(item)) {
                    Image(uiImage: unitImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(2)
                } else {
                    // Fallback if image not found
                    Text(item.name.prefix(1))
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 40, height: 40)
            .onTapGesture {
                // Enable for debugging only
                showDebug.toggle()
            }
            
            // Level number below the icon
            Text("\(item.level)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(4)
                .frame(width: 40) // Set fixed width that fits 3 digits
                .background(
                    item.isMaxed ? Constants.yellow : Color.black.opacity(0.7)
                )
                .foregroundColor(item.isMaxed ? .black : .white)
                .cornerRadius(Constants.innerCornerRadius/3)
                .lineLimit(1) // Ensure text stays on one line
                .minimumScaleFactor(0.8) // Allow scaling down if needed
        }
        .overlay(
            showDebug ? IconDebugHelper(item: item) : nil
        )
    }
    
    private func getUnitImageName(_ item: PlayerItem) -> String {
        let name = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Special cases for hero equipment
        if isHeroEquipment(item) {
            return "equip_\(name)"
        }
        
        // Special cases first
        if item.name.lowercased() == "minion prince" {
            return "minion_prince" // Try simplified name
        } else if item.name.lowercased() == "overgrowth spell" {
            return "spell_overgrowth" // Remove "_spell" suffix
        }
        
        // Special cases for dark troops
        if item.name.lowercased() == "apprentice warden" {
            return "dark_apprentice_warden"
        } else if item.name.lowercased() == "druid" {
            return "dark_druid"
        } else if item.name.lowercased() == "furnace" {
            return "dark_furnace"
        } else if item.name.lowercased() == "minion" || item.name.lowercased().contains("minion") && !item.name.lowercased().contains("prince") {
            return "dark_minion"
        } else if item.name.lowercased() == "hog rider" {
            return "dark_hog_rider"
        } else if item.name.lowercased() == "valkyrie" {
            return "dark_valkyrie"
        } else if item.name.lowercased() == "golem" {
            return "dark_golem"
        } else if item.name.lowercased() == "witch" {
            return "dark_witch"
        } else if item.name.lowercased() == "lava hound" {
            return "dark_lava_hound"
        } else if item.name.lowercased() == "bowler" {
            return "dark_bowler"
        } else if item.name.lowercased() == "ice golem" {
            return "dark_ice_golem"
        } else if item.name.lowercased() == "headhunter" {
            return "dark_headhunter"
        }
        
        // Standard naming logic
        if item.name.contains("Super") {
            return "super_\(name.replacingOccurrences(of: "super_", with: ""))"
        } else if isDarkElixirTroop(item) {
            return "dark_\(name)"
        } else if isSiegeMachine(item) {
            return "siege_\(name)"
        } else if isHero(item) {
            return "hero_\(name)"
        } else if isHeroEquipment(item) {
            return "equip_\(name)"
        } else if isSpell(item) {
            return getSpellImageName(item)
        } else if isPet(item) {
            return "pet_\(name)"
        } else {
            // Regular troop
            return "troop_\(name)"
        }
    }
    
    private func isPet(_ item: PlayerItem) -> Bool {
        let petNames = [
            "L.A.S.S.I", "Electro Owl", "Mighty Yak", "Unicorn",
            "Phoenix", "Poison Lizard", "Diggy", "Frosty",
            "Spirit Fox", "Angry Jelly", "Sneezy"
        ]
        
        return petNames.contains(item.name)
    }
    
    private func getSpellImageName(_ item: PlayerItem) -> String {
        let baseSpellName = item.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "_spell", with: "")
        
        // Special case for Overgrowth Spell
        if baseSpellName == "overgrowth" {
            return "spell_overgrowth"
        }
        
        // Check if it's a dark spell
        if isDarkSpell(item) {
            return "spell_\(baseSpellName)_spell"
        }
        
        // Return standard spell name format
        return "spell_\(baseSpellName)"
    }
    
    private func isDarkElixirTroop(_ item: PlayerItem) -> Bool {
        let darkTroopNames = [
            "minion", "hog rider", "valkyrie", "golem", "witch",
            "lava hound", "bowler", "ice golem", "headhunter",
            "apprentice warden", "druid", "furnace"
        ]
        
        // Special case to exclude Minion Prince from being treated as dark troop
        if item.name.lowercased() == "minion prince" {
            return false
        }
        
        return darkTroopNames.contains { item.name.lowercased().contains($0) }
    }
    
    private func isSiegeMachine(_ item: PlayerItem) -> Bool {
        return item.name.contains("Wall Wrecker") ||
               item.name.contains("Battle Blimp") ||
               item.name.contains("Stone Slammer") ||
               item.name.contains("Siege Barracks") ||
               item.name.contains("Log Launcher") ||
               item.name.contains("Flame Flinger") ||
               item.name.contains("Battle Drill") ||
               item.name.contains("Troop Launcher")
    }
    
    private func isHero(_ item: PlayerItem) -> Bool {
        return item.name.contains("King") ||
               item.name.contains("Queen") ||
               item.name.contains("Warden") ||
               item.name.contains("Champion") ||
               (item.name.contains("Minion Prince") && !item.name.contains("Apprentice"))
    }
    
    private func isHeroEquipment(_ item: PlayerItem) -> Bool {
        return item.village == "heroEquipment" ||
               [
                   "Barbarian Puppet", "Rage Vial", "Earthquake Boots", "Vampstache",
                   "Giant Gauntlet", "Snake Bracelet", "Spiky Ball", "Archer Puppet",
                   "Invisibility Vial", "Giant Arrow", "Healer Puppet", "Action Figure",
                   "Frozen Arrow", "Magic Mirror", "Dark Orb", "Henchmen Puppet",
                   "Metal Pants", "Noble Iron", "Eternal Tome", "Life Gem",
                   "Healing Tome", "Rage Gem", "Lavaloon Puppet", "Fireball",
                   "Royal Gem", "Seeking Shield", "Haste Vial", "Hog Rider Puppet",
                   "Electro Boots", "Rocket Spear"
               ].contains(item.name)
    }
    
    private func isSpell(_ item: PlayerItem) -> Bool {
        return item.village == "home" && item.name.lowercased().contains("spell")
    }
    
    private func isDarkSpell(_ item: PlayerItem) -> Bool {
        let darkSpellNames = [
            "poison", "earthquake", "haste", "skeleton", "bat"
        ]
        
        return darkSpellNames.contains { item.name.lowercased().contains($0) }
    }
    
    private func isSuperTroop(_ item: PlayerItem) -> Bool {
        // Full list of super troops
        let superTroops = [
            "Super Barbarian", "Super Archer", "Sneaky Goblin",
            "Super Wall Breaker", "Super Giant", "Rocket Balloon",
            "Super Wizard", "Super Dragon", "Inferno Dragon",
            "Super Valkyrie", "Super Witch", "Ice Hound",
            "Super Bowler", "Super Miner", "Super Hog Rider"
        ]
        
        return superTroops.contains(item.name) || item.superTroopIsActive == true
    }
}
