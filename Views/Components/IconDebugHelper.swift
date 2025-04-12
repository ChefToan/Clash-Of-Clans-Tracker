// IconDebugHelper.swift
import SwiftUI

struct IconDebugHelper: View {
    let item: PlayerItem
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Debugging Item: \(item.name)")
                .font(.headline)
            
            Text("Image name tried: \(getUnitImageName(item))")
                .font(.subheadline)
                .foregroundColor(.yellow)
            
            if let image = UIImage(named: getUnitImageName(item)) {
                Text("Image found! Size: \(image.size.width)x\(image.size.height)")
                    .foregroundColor(.green)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            } else {
                Text("⚠️ Image not found")
                    .foregroundColor(.red)
                    .font(.headline)
                
                // Try alternate naming patterns
                ForEach(alternateNames(for: item), id: \.self) { name in
                    HStack {
                        Text("Trying: \(name)")
                            .foregroundColor(.gray)
                        
                        if let altImage = UIImage(named: name) {
                            Text("✓")
                                .foregroundColor(.green)
                            
                            Image(uiImage: altImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        } else {
                            Text("✗")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(10)
        .frame(width: 250)
    }
    
    private func getUnitImageName(_ item: PlayerItem) -> String {
        let name = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Hero equipment
        if isHeroEquipment(item) {
            return "equip_\(name)"
        }
        
        // Special cases
        if item.name.lowercased() == "minion prince" {
            return "minion_prince"
        } else if item.name.lowercased() == "overgrowth spell" {
            return "spell_overgrowth"
        }
        
        // Standard naming
        if item.name.contains("Super") {
            return "super_\(name.replacingOccurrences(of: "super_", with: ""))"
        } else if isDarkElixirTroop(item) {
            return "dark_\(name)"
        } else if isSiegeMachine(item) {
            return "siege_\(name)"
        } else if isHero(item) {
            return "hero_\(name)"
        } else if isSpell(item) {
            if isDarkSpell(item) {
                return "spell_\(name.replacingOccurrences(of: "_spell", with: ""))_spell"
            }
            return "spell_\(name.replacingOccurrences(of: "_spell", with: ""))"
        } else if isPet(item) {
            return "pet_\(name)"
        } else {
            return "troop_\(name)"
        }
    }
    
    private func alternateNames(for item: PlayerItem) -> [String] {
        var names: [String] = []
        let baseName = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Try different naming conventions for equipment
        if isHeroEquipment(item) {
            names.append("equip_\(baseName)")
            names.append(baseName)
            names.append("equip_\(item.name.replacingOccurrences(of: " ", with: "_"))")
            return names
        }
        
        // Try different naming conventions
        names.append("dark_\(baseName)")
        names.append("troop_\(baseName)")
        
        if item.name.lowercased() == "minion prince" {
            names.append("hero_minion_prince")
            names.append("minion_prince")
            names.append("prince")
        } else if item.name.lowercased() == "apprentice warden" {
            names.append("dark_apprentice_warden")
            names.append("apprentice_warden")
        } else if item.name.lowercased() == "druid" {
            names.append("dark_druid")
            names.append("druid")
        } else if item.name.lowercased() == "furnace" {
            names.append("dark_furnace")
            names.append("furnace")
        } else if isDarkElixirTroop(item) {
            let nameWithoutSpaces = item.name.lowercased().replacingOccurrences(of: " ", with: "")
            names.append("dark_\(nameWithoutSpaces)")
            names.append(baseName)
        }
        
        return names
    }
    
    // Helper functions
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
    
    private func isPet(_ item: PlayerItem) -> Bool {
        let petNames = ["L.A.S.S.I", "Electro Owl", "Mighty Yak", "Unicorn", "Phoenix", "Poison Lizard", "Diggy", "Frosty", "Spirit Fox", "Angry Jelly", "Sneezy"]
        return petNames.contains(item.name)
    }
    
    private func isDarkElixirTroop(_ item: PlayerItem) -> Bool {
        let darkTroopNames = ["minion", "hog rider", "valkyrie", "golem", "witch", "lava hound", "bowler", "ice golem", "headhunter", "apprentice warden", "druid", "furnace"]
        
        if item.name.lowercased() == "minion prince" {
            return false
        }
        
        return darkTroopNames.contains { item.name.lowercased().contains($0) }
    }
    
    private func isSiegeMachine(_ item: PlayerItem) -> Bool {
        let siegeNames = ["wall wrecker", "battle blimp", "stone slammer", "siege barracks", "log launcher", "flame flinger", "battle drill", "troop launcher"]
        return siegeNames.contains { item.name.lowercased().contains($0) }
    }
    
    private func isHero(_ item: PlayerItem) -> Bool {
        let heroNames = ["king", "queen", "warden", "champion", "minion prince"]
        return heroNames.contains { item.name.lowercased().contains($0) } && !item.name.lowercased().contains("apprentice")
    }
    
    private func isSpell(_ item: PlayerItem) -> Bool {
        return item.village == "home" && item.name.lowercased().contains("spell")
    }
    
    private func isDarkSpell(_ item: PlayerItem) -> Bool {
        let darkSpellNames = ["poison", "earthquake", "haste", "skeleton", "bat"]
        return darkSpellNames.contains { item.name.lowercased().contains($0) }
    }
}
