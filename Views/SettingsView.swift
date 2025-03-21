// SettingsView.swift
import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.managedObjectContext) var moc
    @State private var showClearConfirmation = false
    @State private var showResetConfirmation = false
    @State private var showClearSuccess = false
    @State private var showResetSuccess = false
    
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
                if showClearSuccess {
                    SuccessToast(message: "All players cleared successfully")
                }
                if showResetSuccess {
                    SuccessToast(message: "Settings reset successfully")
                }
            }
        )
    }
    
    private func clearCoreDataPlayers() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlayerEntity")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try moc.execute(batchDeleteRequest)
            try moc.save()
            
            // Also clear any cached player data in UserDefaults
            UserDefaults.standard.removeObject(forKey: "lastSearchedPlayer")
        } catch {
            print("Failed to clear players: \(error)")
        }
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
