// AppState.swift
import SwiftUI

// App-wide state management
class AppState: ObservableObject {
    static let shared = AppState()
    
    // Published properties will cause UI to update when changed
    @Published var profileUpdated = false
    @Published var profileRemoved = false
    @Published var selectedTab: TabSection = .search
    
    // Reset all flags
    func resetFlags() {
        profileUpdated = false
        profileRemoved = false
    }
    
    // Notify that profile has been updated
    func notifyProfileUpdated() {
        profileUpdated = true
        
        // Reset flags after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetFlags()
        }
    }
    
    // Notify that profile has been removed
    func notifyProfileRemoved() {
        profileRemoved = true
        
        // Reset flags after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetFlags()
        }
    }
    
    // Navigate to a specific tab
    func navigateToTab(_ tab: TabSection) {
        selectedTab = tab
    }
}
