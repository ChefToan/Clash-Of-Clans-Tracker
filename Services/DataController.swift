// DataController.swift
import Foundation
import SwiftData

enum DataControllerError: LocalizedError {
    case saveFailed
    case contextSaveFailed
    case decodingFailed
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save profile to database"
        case .contextSaveFailed:
            return "Failed to save context changes"
        case .decodingFailed:
            return "Failed to decode saved data"
        case .noDataFound:
            return "No profile data found"
        }
    }
}

@MainActor
class DataController: ObservableObject {
    static let shared = DataController()
    
    let container: ModelContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Cache for quick access
    @Published private(set) var cachedProfile: PlayerEssentials?
    @Published private(set) var isOffline = false
    
    private init() {
        do {
            container = try ModelContainer(for: PlayerModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    func saveProfile(_ player: PlayerEssentials) async throws {
        let context = container.mainContext
        
        // Start a transaction
        context.autosaveEnabled = false
        defer { context.autosaveEnabled = true }
        
        // Delete any existing profiles first
        let descriptor = FetchDescriptor<PlayerModel>()
        let existing = try context.fetch(descriptor)
        for profile in existing {
            context.delete(profile)
        }
        
        // Save deletion
        if context.hasChanges {
            try context.save()
        }
        
        // Create new profile
        let essentialsData = try encoder.encode(player)
        let model = PlayerModel(
            tag: player.playerTag,
            name: player.playerName,
            expLevel: player.expLevel,
            trophies: player.trophies,
            bestTrophies: player.bestTrophies,
            townHallLevel: player.townHallLevel,
            warStars: player.warStars,
            donations: player.donations,
            donationsReceived: player.donationsReceived,
            essentialsData: essentialsData
        )
        
        context.insert(model)
        
        // Force save immediately
        try context.save()
        
        // Update cache
        cachedProfile = player
        
        // Small delay to ensure persistence
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify save was successful
        let verifyDescriptor = FetchDescriptor<PlayerModel>(
            predicate: #Predicate { $0.tag == player.playerTag }
        )
        let savedModels = try context.fetch(verifyDescriptor)
        
        if savedModels.isEmpty {
            cachedProfile = nil
            throw DataControllerError.saveFailed
        }
    }
    
    func getProfile(forceRefresh: Bool = false) async throws -> PlayerEssentials? {
        // Return cached version if available and not forcing refresh
        if !forceRefresh, let cached = cachedProfile {
            return cached
        }
        
        let context = container.mainContext
        let descriptor = FetchDescriptor<PlayerModel>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        let models = try context.fetch(descriptor)
        
        guard let model = models.first,
              let data = model.essentialsData else {
            cachedProfile = nil
            return nil
        }
        
        do {
            let profile = try decoder.decode(PlayerEssentials.self, from: data)
            cachedProfile = profile
            return profile
        } catch {
            cachedProfile = nil
            print("Failed to decode player essentials: \(error)")
            throw DataControllerError.decodingFailed
        }
    }
    
    func hasProfile() async -> Bool {
        // Check cache first
        if cachedProfile != nil {
            return true
        }
        
        let context = container.mainContext
        let descriptor = FetchDescriptor<PlayerModel>()
        
        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            print("Failed to check profile existence: \(error)")
            return false
        }
    }
    
    func deleteProfile() async throws {
        let context = container.mainContext
        context.autosaveEnabled = false
        defer { context.autosaveEnabled = true }
        
        let descriptor = FetchDescriptor<PlayerModel>()
        let profiles = try context.fetch(descriptor)
        
        for profile in profiles {
            context.delete(profile)
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        // Clear cache
        cachedProfile = nil
        
        // Add a small delay to ensure deletion is complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func setOfflineStatus(_ offline: Bool) {
        isOffline = offline
    }
}
