// SettingsView.swift
import SwiftUI
import AlertToast

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var tabState: TabState
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#1a1a2e"), Color(hex: "#0f0f1e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.gray)
                                Text("PROFILE MANAGEMENT")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 4)

                            Button(action: {
                                HapticManager.shared.lightImpactFeedback()
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Remove My Profile")
                                        .foregroundColor(.red)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal)

                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.gray)
                                Text("ABOUT")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 4)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Application")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                    Spacer()
                                    Text("Clash of Clans Tracker")
                                        .foregroundColor(.white)
                                        .font(.body)
                                }

                                HStack {
                                    Text("Version")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                    Spacer()
                                    Text("1.0.0")
                                        .foregroundColor(.white)
                                        .font(.body)
                                }

                                HStack {
                                    Text("Compatibility")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                    Spacer()
                                    Text("iOS 17.0 or above")
                                        .foregroundColor(.white)
                                        .font(.body)
                                }

                                HStack {
                                    Text("Developer")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                    Spacer()
                                    Text("Toan Pham")
                                        .foregroundColor(.white)
                                        .font(.body)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.shared.lightImpactFeedback()
                }
                Button("Delete", role: .destructive) {
                    HapticManager.shared.mediumImpactFeedback()
                    Task {
                        await viewModel.deleteProfile()
                        showDeleteSuccess = true
                        // Switch to profile tab after deletion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            tabState.switchToProfile()
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your saved profile. This action cannot be undone.")
            }
            .toast(isPresenting: $showDeleteSuccess, duration: 2) {
                AlertToast(type: .complete(Color.green), title: "Profile Deleted Successfully")
            }
        }
    }
}
