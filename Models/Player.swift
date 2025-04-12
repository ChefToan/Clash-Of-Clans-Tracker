// Player.swift
import Foundation

// Main player model
struct Player: Codable, Identifiable {
    var id: String { tag }
    let tag: String
    let name: String
    let expLevel: Int
    let trophies: Int
    let bestTrophies: Int
    let donations: Int
    let donationsReceived: Int
    let attackWins: Int
    let defenseWins: Int
    let townHallLevel: Int
    let townHallWeaponLevel: Int?
    let warStars: Int
    let clanCapitalContributions: Int
    let clan: PlayerClan?
    let league: League?
    let troops: [PlayerItem]?
    let heroes: [PlayerItem]?
    let spells: [PlayerItem]?
    let heroEquipment: [PlayerItem]?
    let role: String?
    let builderHallLevel: Int?
    let builderBaseTrophies: Int?
    let bestBuilderBaseTrophies: Int?
    
    // Optional legendStatistics
    let legends: LegendStatistics?
    
    enum CodingKeys: String, CodingKey {
        case tag, name, expLevel, trophies, bestTrophies, donations,
             donationsReceived, attackWins, defenseWins, townHallLevel,
             townHallWeaponLevel, warStars, clanCapitalContributions,
             clan, league, troops, heroes, spells, heroEquipment, role,
             builderHallLevel, builderBaseTrophies, bestBuilderBaseTrophies
        case legends = "legendStatistics"
    }
    
    // Initializer with defaults for missing values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        tag = try container.decode(String.self, forKey: .tag)
        name = try container.decode(String.self, forKey: .name)
        
        // Fields with default values if missing
        expLevel = try container.decodeIfPresent(Int.self, forKey: .expLevel) ?? 1
        trophies = try container.decodeIfPresent(Int.self, forKey: .trophies) ?? 0
        bestTrophies = try container.decodeIfPresent(Int.self, forKey: .bestTrophies) ?? 0
        donations = try container.decodeIfPresent(Int.self, forKey: .donations) ?? 0
        donationsReceived = try container.decodeIfPresent(Int.self, forKey: .donationsReceived) ?? 0
        attackWins = try container.decodeIfPresent(Int.self, forKey: .attackWins) ?? 0
        defenseWins = try container.decodeIfPresent(Int.self, forKey: .defenseWins) ?? 0
        townHallLevel = try container.decodeIfPresent(Int.self, forKey: .townHallLevel) ?? 1
        townHallWeaponLevel = try container.decodeIfPresent(Int.self, forKey: .townHallWeaponLevel)
        warStars = try container.decodeIfPresent(Int.self, forKey: .warStars) ?? 0
        clanCapitalContributions = try container.decodeIfPresent(Int.self, forKey: .clanCapitalContributions) ?? 0
        builderHallLevel = try container.decodeIfPresent(Int.self, forKey: .builderHallLevel)
        builderBaseTrophies = try container.decodeIfPresent(Int.self, forKey: .builderBaseTrophies)
        bestBuilderBaseTrophies = try container.decodeIfPresent(Int.self, forKey: .bestBuilderBaseTrophies)
        
        // Optional fields
        clan = try container.decodeIfPresent(PlayerClan.self, forKey: .clan)
        league = try container.decodeIfPresent(League.self, forKey: .league)
        troops = try container.decodeIfPresent([PlayerItem].self, forKey: .troops)
        heroes = try container.decodeIfPresent([PlayerItem].self, forKey: .heroes)
        spells = try container.decodeIfPresent([PlayerItem].self, forKey: .spells)
        heroEquipment = try container.decodeIfPresent([PlayerItem].self, forKey: .heroEquipment)
        
        // Parse role with special handling for "admin" -> "Elder"
        if let roleValue = try container.decodeIfPresent(String.self, forKey: .role) {
            switch roleValue.lowercased() {
            case "admin":
                role = "Elder"
            case "coleader":
                role = "Co-Leader"
            case "member":
                role = "Member"
            default:
                role = roleValue
            }
        } else {
            role = nil
        }
        
        legends = try container.decodeIfPresent(LegendStatistics.self, forKey: .legends)
    }
    
    // Custom initializer for creating Player from scratch
    init(tag: String, name: String, expLevel: Int, trophies: Int, bestTrophies: Int,
         donations: Int, donationsReceived: Int, attackWins: Int, defenseWins: Int,
         townHallLevel: Int, townHallWeaponLevel: Int?, warStars: Int,
         clanCapitalContributions: Int, clan: PlayerClan?, league: League?,
         troops: [PlayerItem]?, heroes: [PlayerItem]?, spells: [PlayerItem]?,
         heroEquipment: [PlayerItem]?, role: String?, builderHallLevel: Int?,
         builderBaseTrophies: Int?, bestBuilderBaseTrophies: Int?, legends: LegendStatistics?) {
        
        self.tag = tag
        self.name = name
        self.expLevel = expLevel
        self.trophies = trophies
        self.bestTrophies = bestTrophies
        self.donations = donations
        self.donationsReceived = donationsReceived
        self.attackWins = attackWins
        self.defenseWins = defenseWins
        self.townHallLevel = townHallLevel
        self.townHallWeaponLevel = townHallWeaponLevel
        self.warStars = warStars
        self.clanCapitalContributions = clanCapitalContributions
        self.clan = clan
        self.league = league
        self.troops = troops
        self.heroes = heroes
        self.spells = spells
        self.heroEquipment = heroEquipment
        
        // Handle "admin" role conversion
        if let roleValue = role, roleValue.lowercased() == "admin" {
            self.role = "Elder"
        } else {
            self.role = role
        }
        
        self.builderHallLevel = builderHallLevel
        self.builderBaseTrophies = builderBaseTrophies
        self.bestBuilderBaseTrophies = bestBuilderBaseTrophies
        self.legends = legends
    }
}

// Player clan information
struct PlayerClan: Codable {
    let tag: String
    let name: String
    let clanLevel: Int
    let badgeUrls: BadgeUrls?
}

struct BadgeUrls: Codable {
    let small: String?
    let medium: String?
    let large: String?
}

// League information
struct League: Codable {
    let id: Int
    let name: String
    let iconUrls: IconUrls?
}

struct IconUrls: Codable {
    let small: String?
    let medium: String?
    let large: String?
    let tiny: String?
}

// Legend league stats
struct LegendStatistics: Codable {
    let legendTrophies: Int
    let currentSeason: Season?
    let previousSeason: Season?
    let bestSeason: Season?
}

struct Season: Codable {
    let id: String?
    let rank: Int?
    let trophies: Int
}

// Player items like troops, heroes, spells
struct PlayerItem: Codable, Identifiable, Equatable {
    var id: String { name + String(level) }
    let name: String
    let level: Int
    let maxLevel: Int
    let village: String
    let superTroopIsActive: Bool?
    
    var isMaxed: Bool {
        return level >= maxLevel
    }
}

extension Player: Equatable {
    static func == (lhs: Player, rhs: Player) -> Bool {
        // Since player tags are unique identifiers, we can compare by tag
        return lhs.tag == rhs.tag
    }
}
