// PlayerModel.swift
import Foundation
import SwiftData

@Model
final class PlayerModel {
    var tag: String
    var name: String
    var expLevel: Int
    var trophies: Int
    var bestTrophies: Int
    var attackWins: Int
    var defenseWins: Int
    var townHallLevel: Int
    var warStars: Int
    var donations: Int
    var donationsReceived: Int
    var clanCapitalContributions: Int
    var isMyProfile: Bool
    var builderHallLevel: Int?
    var builderBaseTrophies: Int?
    var bestBuilderBaseTrophies: Int?
    
    // Complex objects stored as JSON data
    var clanData: Data?
    var leagueData: Data?
    
    init(
        tag: String,
        name: String,
        expLevel: Int,
        trophies: Int,
        bestTrophies: Int,
        attackWins: Int,
        defenseWins: Int,
        townHallLevel: Int,
        warStars: Int,
        donations: Int,
        donationsReceived: Int,
        clanCapitalContributions: Int,
        isMyProfile: Bool = false,
        builderHallLevel: Int? = nil,
        builderBaseTrophies: Int? = nil,
        bestBuilderBaseTrophies: Int? = nil,
        clanData: Data? = nil,
        leagueData: Data? = nil
    ) {
        self.tag = tag
        self.name = name
        self.expLevel = expLevel
        self.trophies = trophies
        self.bestTrophies = bestTrophies
        self.attackWins = attackWins
        self.defenseWins = defenseWins
        self.townHallLevel = townHallLevel
        self.warStars = warStars
        self.donations = donations
        self.donationsReceived = donationsReceived
        self.clanCapitalContributions = clanCapitalContributions
        self.isMyProfile = isMyProfile
        self.builderHallLevel = builderHallLevel
        self.builderBaseTrophies = builderBaseTrophies
        self.bestBuilderBaseTrophies = bestBuilderBaseTrophies
        self.clanData = clanData
        self.leagueData = leagueData
    }
}
