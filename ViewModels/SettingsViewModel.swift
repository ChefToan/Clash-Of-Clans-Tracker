// SettingsViewModel.swift
import Foundation
import SwiftUI
import SwiftData

class SettingsViewModel: ObservableObject {
    @Published var selectedTimezone: String
    @Published var autoRefresh: Bool
    @Published var showResetConfirmation = false
    @Published var showSuccessToast = false
    @Published var successMessage = ""
    
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
        
        // Notify any listeners that the setting has changed
        NotificationCenter.default.post(name: Notification.Name("AutoRefreshSettingChanged"), object: nil)
        
        // If enabling, show a success message
        if enabled {
            showSuccess(message: "Auto-refresh enabled")
        }
    }

    func getNextRefreshTime() -> String {
        return RefreshScheduler.shared.formatNextResetTime()
    }

    func get5AMUTCInUserTimezone() -> String {
        return RefreshScheduler.shared.get5AMUTCInUserTimezone()
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
    
    func showSuccess(message: String) {
        self.successMessage = message
        self.showSuccessToast = true
    }
    
    func hideSuccessToast() {
        self.showSuccessToast = false
    }
    
    @MainActor
    func removeMyProfile() async -> Bool {
        print("SettingsViewModel - Removing profile")
        let result = await DataController.shared.removeMyProfile()
        
        if result {
            print("SettingsViewModel - Profile successfully removed")
            // Set an additional flag in UserDefaults to ensure profile removal is recognized
            UserDefaults.standard.set(false, forKey: "hasClaimedProfile")
            try? await Task.sleep(nanoseconds: 100_000_000) // Small delay to ensure database operations complete
        } else {
            print("SettingsViewModel - Failed to remove profile")
        }
        TabState.shared.handleTabSelection(.profile)
        return result
    }
    
    @MainActor
    func clearAllData() async {
        print("SettingsViewModel - Clearing all data")
        
        // Clear SwiftData store
        await DataController.shared.clearAllData()
        
        // Clear UserDefaults
        clearUserDefaults()
        
        // Reset AppState to initial values
        AppState.shared.notifyProfileRemoved()
        
        // Extra delay to ensure all updates are processed
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        print("SettingsViewModel - All data cleared successfully")
    }
    
    func clearAllSettings() {
        // Reset to defaults
        selectedTimezone = TimeZone.current.identifier
        autoRefresh = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(selectedTimezone, forKey: "selectedTimezone")
        UserDefaults.standard.set(autoRefresh, forKey: "autoRefresh")
        
        // Also clear any user-specific data
        UserDefaults.standard.removeObject(forKey: "lastSearchedPlayer")
        UserDefaults.standard.removeObject(forKey: "lastSearchTimestamp")
        
        // Redirect to My Profile tab
        TabState.shared.handleTabSelection(.profile)
    }
    
    private func clearUserDefaults() {
        // Get the app domain
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
        
        // Reset critical values to defaults
        UserDefaults.standard.set(TimeZone.current.identifier, forKey: "selectedTimezone")
        UserDefaults.standard.set(false, forKey: "hasClaimedProfile")
        UserDefaults.standard.set(false, forKey: "autoRefresh")
        
        // Update published properties
        self.selectedTimezone = TimeZone.current.identifier
        self.autoRefresh = false
    }
}
