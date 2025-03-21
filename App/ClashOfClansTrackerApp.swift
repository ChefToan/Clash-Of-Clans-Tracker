// ClashOfClansTrackerApp.swift
import SwiftUI
import SwiftData

@main
struct ClashOfClansTrackerApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    SearchPlayersView()
                        .navigationBarHidden(true)
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Players")
                }
                
                NavigationStack {
                    MyProfileView()
                        .navigationBarHidden(true)
                }
                .tabItem {
                    Image(systemName: "person")
                    Text("My Profile")
                }
                
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
            }
            // Force dark mode to match the design
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
            // Set up SwiftData model container
            .modelContainer(dataController.getModelContainer())
            // Load the shared UserDefaults for state persistence
            .onAppear {
                setupAppDefaults()
            }
        }
    }
    
    private func setupAppDefaults() {
        // Set initial defaults if they don't exist
        if UserDefaults.standard.string(forKey: "selectedTimezone") == nil {
            UserDefaults.standard.set(TimeZone.current.identifier, forKey: "selectedTimezone")
        }
    }
}
