// SettingsViewModel.swift
import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    
    func deleteProfile() async {
        do {
            try await DataController.shared.deleteProfile()
            HapticManager.shared.successFeedback()
            
            // Post notification to update profile view
            NotificationCenter.default.post(name: Notification.Name("ProfileDeleted"), object: nil)
        } catch {
            print("Failed to delete profile: \(error)")
        }
    }
}
