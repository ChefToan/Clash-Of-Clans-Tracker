// ItemView.swift
import SwiftUI

struct ItemView: View {
    let item: GameItem
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(8)
                
                if let image = UIImage(named: getImageName()) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                } else {
                    Text(String(item.name.prefix(2)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Level
            Text("\(item.level)")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(item.isMaxed ? Color.yellow : Color.black.opacity(0.7))
                .foregroundColor(item.isMaxed ? .black : .white)
                .cornerRadius(4)
        }
    }
    
    private func getImageName() -> String {
        let name = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Add appropriate prefix based on item type
        if item.village == "home" {
            if item.name.contains("Spell") {
                // Handle spell naming conventions
                let spellName = item.name.replacingOccurrences(of: " Spell", with: "")
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                
                // Special cases for spells with different naming conventions
                switch spellName {
                case "lightning":
                    return "spell_lightning"
                case "healing":
                    return "spell_healing"
                case "rage":
                    return "spell_rage"
                case "jump":
                    return "spell_jump"
                case "freeze":
                    return "spell_freeze"
                case "clone":
                    return "spell_clone"
                case "invisibility":
                    return "spell_invisibility"
                case "recall":
                    return "spell_recall"
                case "poison":
                    return "spell_poison_spell"
                case "earthquake":
                    return "spell_earthquake_spell"
                case "haste":
                    return "spell_haste_spell"
                case "skeleton":
                    return "spell_skeleton_spell"
                case "bat":
                    return "spell_bat_spell"
                case "overgrowth":
                    return "spell_overgrowth"
                case "revive":
                    return "spell_revive"
                default:
                    return "spell_\(spellName)"
                }
            } else if ["L.A.S.S.I", "Electro Owl", "Mighty Yak", "Unicorn", "Phoenix",
                       "Poison Lizard", "Diggy", "Frosty", "Spirit Fox", "Angry Jelly",
                       "Sneezy"].contains(item.name) {
                return "pet_\(name)"
            } else if ["Wall Wrecker", "Battle Blimp", "Stone Slammer", "Siege Barracks",
                       "Log Launcher", "Flame Flinger", "Battle Drill", "Troop Launcher"].contains(where: item.name.contains) {
                return "siege_\(name)"
            } else if ["Barbarian King", "Archer Queen", "Minion Prince", "Grand Warden",
                       "Royal Champion"].contains(item.name) {
                return "hero_\(name)"
            } else {
                // Check if it's equipment
                let equipmentNames = ["Barbarian Puppet", "Rage Vial", "Earthquake Boots", "Vampstache",
                                    "Giant Gauntlet", "Snake Bracelet", "Spiky Ball", "Archer Puppet",
                                    "Invisibility Vial", "Giant Arrow", "Healer Puppet", "Action Figure",
                                    "Frozen Arrow", "Magic Mirror", "Dark Orb", "Henchmen Puppet",
                                    "Metal Pants", "Noble Iron", "Eternal Tome", "Life Gem",
                                    "Healing Tome", "Rage Gem", "Lavaloon Puppet", "Fireball",
                                    "Royal Gem", "Seeking Shield", "Haste Vial", "Hog Rider Puppet",
                                    "Electro Boots", "Rocket Spear"]
                
                if equipmentNames.contains(item.name) {
                    return "equip_\(name)"
                }
                
                // Check if dark troop
                let darkTroops = ["Minion", "Hog Rider", "Valkyrie", "Golem", "Witch",
                                "Lava Hound", "Bowler", "Ice Golem", "Headhunter",
                                "Apprentice Warden", "Druid", "Furnace"]
                
                if darkTroops.contains(where: item.name.contains) {
                    return "dark_\(name)"
                }
                
                return "troop_\(name)"
            }
        }
        
        return name
    }
}
