//  ItemView.swift
import SwiftUI

struct ItemView: View {
    let item: PlayerItem
    
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
                }
            }
            .frame(width: 40, height: 40)
            
            // Level number below the icon
            Text("\(item.level)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(4)
                .frame(minWidth: 30)
                .background(
                    item.isMaxed ? Constants.yellow : Color.black.opacity(0.7)
                )
                .foregroundColor(item.isMaxed ? .black : .white)
                .cornerRadius(Constants.innerCornerRadius/3)
        }
    }
    
    private func getUnitImageName(_ item: PlayerItem) -> String {
        let name = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Determine unit type
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
        let name = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        let baseName = name.replacingOccurrences(of: "_spell", with: "")
        
        if isDarkSpell(item) {
            return "dark_spell_\(baseName)"
        }
        return "spell_\(baseName)"
    }
    
    private func isDarkElixirTroop(_ item: PlayerItem) -> Bool {
        let darkTroopNames = [
            "minion", "hog rider", "valkyrie", "golem", "witch",
            "lava hound", "bowler", "ice golem", "headhunter",
            "apprentice warden", "druid", "furnace"
        ]
        
        return darkTroopNames.contains { item.name.lowercased().contains($0) }
    }
    
    private func isSiegeMachine(_ item: PlayerItem) -> Bool {
        let siegeMachines = [
            "wall wrecker", "battle blimp", "stone slammer", "siege barracks",
            "log launcher", "flame flinger", "battle drill", "troop launcher"
        ]
        
        return siegeMachines.contains { item.name.lowercased().contains($0) }
    }
    
    private func isHero(_ item: PlayerItem) -> Bool {
        let heroes = [
            "barbarian king", "archer queen", "grand warden", "royal champion",
            "battle machine", "battle copter", "minion prince"
        ]
        
        return heroes.contains { item.name.lowercased().contains($0) }
    }
    
    private func isHeroEquipment(_ item: PlayerItem) -> Bool {
        return item.village == "heroEquipment"
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
}
