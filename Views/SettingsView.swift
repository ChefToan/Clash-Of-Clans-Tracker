// SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showClearConfirmation = false
    @State private var showResetConfirmation = false
    @State private var showRemoveProfileConfirmation = false
    @State private var showClearDataConfirmation = false
    @EnvironmentObject var appState: AppState
    @ObservedObject var tabState = TabState.shared // Add tab state reference
    
    var body: some View {
        List {
            // Timezone section
            Section(header: Label("Timezone", systemImage: "globe")) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Current timezone:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(viewModel.selectedTimezone.replacingOccurrences(of: "_", with: " "))
                        .font(.headline)
                    
                    NavigationLink(destination: TimezoneListView(selectedTimezone: $viewModel.selectedTimezone)) {
                        HStack {
                            Text("Change Timezone")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            
            // Profile & Data Management section
            Section(header: Label("Profile Management", systemImage: "person")) {
                Button(action: {
                    showRemoveProfileConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                            .foregroundColor(.red)
                        Text("Remove My Profile")
                            .foregroundColor(.red)
                    }
                }
                .alert(isPresented: $showRemoveProfileConfirmation) {
                    Alert(
                        title: Text("Remove My Profile"),
                        message: Text("Are you sure you want to remove your profile? This action cannot be undone."),
                        primaryButton: .destructive(Text("Remove")) {
                            Task {
                                if await viewModel.removeMyProfile() {
                                    // Notify AppState that profile has been removed
                                    appState.notifyProfileRemoved()
                                    viewModel.showSuccess(message: "Profile removed successfully")
                                    
                                    // Redirect to Profile tab after delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        tabState.selectedTab = .profile
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                // Clear All Data option
                Button(action: {
                    showClearDataConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All App Data")
                            .foregroundColor(.red)
                    }
                }
                .alert(isPresented: $showClearDataConfirmation) {
                    Alert(
                        title: Text("Clear All App Data"),
                        message: Text("This will remove ALL saved data including profiles, search history, and settings. This action cannot be undone."),
                        primaryButton: .destructive(Text("Clear Everything")) {
                            Task {
                                await viewModel.clearAllData()
                                // Notify AppState that profile has been removed
                                appState.notifyProfileRemoved()
                                viewModel.showSuccess(message: "All data cleared successfully")
                                
                                // Redirect to Profile tab after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    tabState.selectedTab = .profile
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            
            // About section
            Section(header: Label("About", systemImage: "info.circle")) {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(title: "Application", content: "Clash of Clans Tracker")
                    InfoRow(title: "Version", content: "1.0.0")
                    InfoRow(title: "Compatibility", content: "iOS 17.0 or above")
                    InfoRow(title: "Developer", content: "Your Name")
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Settings")
        .background(Constants.bgDark)
        .listStyle(InsetGroupedListStyle())
        .overlay(
            Group {
                if viewModel.showSuccessToast {
                    SuccessToast(message: viewModel.successMessage)
                        .onAppear {
                            // Auto-hide the toast after a few seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                viewModel.hideSuccessToast()
                            }
                        }
                }
            }
        )
    }
}

struct SuccessToast: View {
    var message: String
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Constants.green)
                Text(message)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: true)
        .zIndex(100)
    }
}

struct TimezoneListView: View {
    @Binding var selectedTimezone: String
    @Environment(\.dismiss) private var dismiss
    
    private let timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
    
    var body: some View {
        List {
            ForEach(timezones, id: \.self) { timezone in
                Button(action: {
                    selectedTimezone = timezone
                    UserDefaults.standard.set(timezone, forKey: "selectedTimezone")
                    dismiss()
                }) {
                    HStack {
                        Text(formatTimezone(timezone))
                        Spacer()
                        if timezone == selectedTimezone {
                            Image(systemName: "checkmark")
                                .foregroundColor(Constants.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Timezone")
    }
    
    private func formatTimezone(_ timezone: String) -> String {
        guard let tz = TimeZone(identifier: timezone) else { return timezone }
        let offsetSeconds = tz.secondsFromGMT()
        let hours = offsetSeconds / 3600
        let minutes = abs(offsetSeconds / 60) % 60
        
        let sign = hours >= 0 ? "+" : ""
        let minuteString = minutes > 0 ? ":\(String(format: "%02d", minutes))" : ""
        
        return "\(timezone.replacingOccurrences(of: "_", with: " ")) (GMT\(sign)\(hours)\(minuteString))"
    }
}

struct InfoRow: View {
    let title: String
    let content: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(content)
                .fontWeight(.medium)
        }
    }
}
