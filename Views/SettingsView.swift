// SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showRemoveProfileConfirmation = false
    @EnvironmentObject var appState: AppState
    @ObservedObject var tabState = TabState.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        List {
            // Appearance section
            Section(header: Label("Appearance", systemImage: "paintbrush")) {
                Toggle(isOn: $isDarkMode) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .yellow : .orange)
                        Text("Dark Mode")
                    }
                }
                .onChange(of: isDarkMode) { _, _ in
                    // Trigger haptic feedback on change
                    HapticManager.shared.selectionFeedback()
                }
            }
            
            // Profile Management section
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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        tabState.selectedTab = .profile
                                    }
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
                    InfoRow(title: "Developer", content: "Toan Pham")
                }
                .padding(.vertical, 5)
            }
        }
        .background(Constants.background)
        .scrollContentBackground(.hidden)
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

struct InfoRow: View {
    let title: String
    let content: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(content)
                .fontWeight(.medium)
        }
    }
}
