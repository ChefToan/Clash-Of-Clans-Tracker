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
    var townHallLevel: Int
    var warStars: Int
    var donations: Int
    var donationsReceived: Int
    var lastUpdated: Date
    
    // Store the complete JSON data for complex objects
    var essentialsData: Data?
    
    init(tag: String, name: String, expLevel: Int, trophies: Int,
         bestTrophies: Int, townHallLevel: Int, warStars: Int,
         donations: Int, donationsReceived: Int, essentialsData: Data? = nil) {
        self.tag = tag
        self.name = name
        self.expLevel = expLevel
        self.trophies = trophies
        self.bestTrophies = bestTrophies
        self.townHallLevel = townHallLevel
        self.warStars = warStars
        self.donations = donations
        self.donationsReceived = donationsReceived
        self.lastUpdated = Date()
        self.essentialsData = essentialsData
    }
}
