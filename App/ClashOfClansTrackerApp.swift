// ClashOfClansTrackerApp.swift
import SwiftUI
import SwiftData

enum TabSection: Int {
    case search = 0
    case profile = 1
    case settings = 2
}

class TabState: ObservableObject {
    @Published var selectedTab: TabSection = .search
    @Published var shouldResetSearch = false
    @Published var lastSelectedTab: TabSection? = nil
    
    func handleTabSelection(_ tab: TabSection) {
        // If tapping on the search tab when it's already selected, reset to search input
        if tab == .search && selectedTab == .search {
            shouldResetSearch = true
            // Reset this flag after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shouldResetSearch = false
            }
        }
        
        lastSelectedTab = selectedTab
        selectedTab = tab
    }
}

@main
struct ClashOfClansTrackerApp: App {
    @StateObject private var dataController = DataController.shared
    @StateObject private var tabState = TabState()
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: Binding(
                get: { self.tabState.selectedTab },
                set: { self.tabState.handleTabSelection($0) }
            )) {
                NavigationStack {
                    SearchPlayersView(tabState: tabState)
                        .navigationBarHidden(true)
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Players")
                }
                .tag(TabSection.search)
                
                NavigationStack {
                    MyProfileView()
                        .navigationBarHidden(true)
                }
                .tabItem {
                    Image(systemName: "person")
                    Text("My Profile")
                }
                .tag(TabSection.profile)
                
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(TabSection.settings)
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
