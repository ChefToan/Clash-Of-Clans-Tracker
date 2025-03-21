// SettingsViewModel.swift
import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var selectedTimezone: String
    @Published var autoRefresh: Bool
    @Published var showResetConfirmation = false
    
    init() {
        // Initialize with stored values or defaults
        self.selectedTimezone = UserDefaults.standard.string(forKey: "selectedTimezone") ?? TimeZone.current.identifier
        self.autoRefresh = UserDefaults.standard.bool(forKey: "autoRefresh")
    }
    
    func saveTimezone(_ timezone: String) {
        selectedTimezone = timezone
        UserDefaults.standard.set(timezone, forKey: "selectedTimezone")
    }
    
    func setAutoRefresh(enabled: Bool) {
        autoRefresh = enabled
        UserDefaults.standard.set(autoRefresh, forKey: "autoRefresh")
    }
    
    func resetAllSettings() {
        // Reset to defaults
        selectedTimezone = TimeZone.current.identifier
        autoRefresh = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(selectedTimezone, forKey: "selectedTimezone")
        UserDefaults.standard.set(autoRefresh, forKey: "autoRefresh")
        
        // Also clear any user-specific data
        UserDefaults.standard.removeObject(forKey: "lastSearchedPlayer")
        UserDefaults.standard.removeObject(forKey: "lastSearchTimestamp")
    }
}
