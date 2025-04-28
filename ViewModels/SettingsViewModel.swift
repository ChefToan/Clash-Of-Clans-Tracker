// SettingsViewModel.swift
import Foundation
import SwiftUI
import SwiftData

class SettingsViewModel: ObservableObject {
    @Published var showSuccessToast = false
    @Published var successMessage = ""
    
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
            
            // Post a notification to clear caches
            NotificationCenter.default.post(name: Notification.Name("ProfileRemoved"), object: nil)
            
            // Small delay to ensure database operations complete
            try? await Task.sleep(nanoseconds: 100_000_000)
        } else {
            print("SettingsViewModel - Failed to remove profile")
        }
        return result
    }
}
