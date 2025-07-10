// PlayerEssentials.swift
import Foundation

// Main player essentials model matching the API response
struct PlayerEssentials: Codable, Identifiable, Hashable {
    var id: String { playerTag }
    
    let clan: ClanInfo?
    let clanCapitalContributions: Int
    let defenseWins: Int
    let donations: Int
    let donationsReceived: Int
    let expLevel: Int
    let league: LeagueInfo?
    let role: String?
    let achievements: Achievement?
    let legends: LegendsInfo?
    let trophies: Int
    let warPreference: String?
    let warStars: Int
    let townHallLevel: Int
    let heroes: [GameItem]
    let heroEquipment: HeroEquipment
    let pets: [GameItem]
    let elixirTroops: [GameItem]
    let darkElixirTroops: [GameItem]
    let siegeMachines: [GameItem]
    let elixirSpells: [GameItem]
    let darkElixirSpells: [GameItem]
    let playerName: String
    let playerTag: String
    
    // Computed property for best trophies
    var bestTrophies: Int {
        return achievements?.value ?? trophies
    }
    
    // Computed property to check if player is in Legend League
    var isInLegendsLeague: Bool {
        guard let league = self.league else { return false }
        return league.safeName.lowercased().contains("legend")
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(playerTag)
    }
    
    static func == (lhs: PlayerEssentials, rhs: PlayerEssentials) -> Bool {
        lhs.playerTag == rhs.playerTag
    }
}

// Supporting models - Made ClanInfo properties optional to handle incomplete data
struct ClanInfo: Codable, Hashable {
    let name: String?
    let tag: String?
    let badgeUrls: BadgeUrls?
    let clanLevel: Int?
    
    // Computed properties to provide safe defaults
    var safeName: String {
        if let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return "No Clan"
    }
    
    var safeTag: String {
        if let tag = tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return tag
        }
        return "#UNKNOWN"
    }
    
    var safeBadgeUrls: BadgeUrls {
        return badgeUrls ?? BadgeUrls(small: "", medium: "", large: "")
    }
    
    var safeClanLevel: Int {
        return clanLevel ?? 0
    }
}

struct BadgeUrls: Codable, Hashable {
    let small: String
    let medium: String
    let large: String
}

struct LeagueInfo: Codable, Hashable {
    let name: String?
    
    // Computed property to provide safe default
    var safeName: String {
        if let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return "Unranked"
    }
}

struct Achievement: Codable, Hashable {
    let completionInfo: String
    let info: String
    let name: String
    let stars: Int
    let target: Int
    let value: Int
    let village: String
}

struct LegendsInfo: Codable, Hashable {
    let globalRank: Int?
    let localRank: Int?
    let previousSeason: SeasonInfo?
    let bestSeason: SeasonInfo?
    
    enum CodingKeys: String, CodingKey {
        case globalRank = "global_rank"
        case localRank = "local_rank"
        case previousSeason = "previous_season"
        case bestSeason = "best_season"
    }
}

struct SeasonInfo: Codable, Hashable {
    let id: String?
    let rank: Int?
    let trophies: Int?
}

struct GameItem: Codable, Identifiable, Hashable {
    var id: String { "\(name)_\(level)" }
    
    let name: String
    let level: Int
    let maxLevel: Int
    let village: String
    let order: Int
    
    var isMaxed: Bool {
        return level >= maxLevel
    }
}

struct HeroEquipment: Codable, Hashable {
    let barbarianKing: [EquipmentItem]
    let archerQueen: [EquipmentItem]
    let minionPrince: [EquipmentItem]
    let grandWarden: [EquipmentItem]
    let royalChampion: [EquipmentItem]
}

struct EquipmentItem: Codable, Identifiable, Hashable {
    var id: String { "\(name)_\(level)" }
    
    let name: String
    let level: Int
    let maxLevel: Int
    let village: String
    let isEpic: Bool
    let isEquipped: Bool
    let order: Int
    
    var isMaxed: Bool {
        return level >= maxLevel
    }
}
