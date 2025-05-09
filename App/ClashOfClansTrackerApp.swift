// ClashOfClansTrackerApp.swift
import SwiftUI
import SwiftData

enum TabSection: Int {
    case search = 0
    case profile = 1
    case settings = 2
}

class TabState: ObservableObject {
    static let shared = TabState()
        
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
        
        // Add haptic feedback when changing tabs
        if tab != selectedTab {
            HapticManager.shared.selectionFeedback()
        }
        
        lastSelectedTab = selectedTab
        selectedTab = tab
    }

    // Initialize with the appropriate tab based on whether user has a profile
    func initializeWithDefaultTab(hasProfile: Bool) {
        selectedTab = hasProfile ? .profile : .search
    }
    
    // Update tab selection from AppState
    func updateFromAppState() {
        selectedTab = AppState.shared.selectedTab
    }
}

@main
struct ClashOfClansTrackerApp: App {
    @StateObject private var dataController = DataController.shared
    @StateObject private var tabState = TabState.shared
    @StateObject private var appState = AppState.shared
    @State private var initialTabSet = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: Binding(
                get: { self.tabState.selectedTab },
                set: { self.tabState.handleTabSelection($0) }
            )) {
                NavigationStack {
                    SearchPlayersView(tabState: tabState)
                        .environmentObject(appState)
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Players")
                }
                .tag(TabSection.search)
                
                NavigationStack {
                    MyProfileView(tabState: tabState)
                        .navigationTitle("My Profile")
                        .environmentObject(appState)
                }
                .tabItem {
                    Image(systemName: "person")
                    Text("My Profile")
                }
                .tag(TabSection.profile)
                
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                        .environmentObject(appState)
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(TabSection.settings)
            }
            // Apply dark/light mode based on user preference
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .modelContainer(dataController.getModelContainer())
            .onAppear {
                setupInitialTab()
            }
            .task {
                if !initialTabSet {
                    await setupInitialTabAsync()
                    initialTabSet = true
                }
            }
            .onChange(of: appState.selectedTab) { _, newTab in
                tabState.selectedTab = newTab
            }
        }
    }
    
    private func setupInitialTab() {
        // Check UserDefaults first for a quick startup
        if UserDefaults.standard.bool(forKey: "hasClaimedProfile") {
            tabState.initializeWithDefaultTab(hasProfile: true)
            initialTabSet = true
        }
    }
    
    @MainActor
    private func setupInitialTabAsync() async {
        // Check if a profile exists in SwiftData
        let hasProfile = await dataController.hasMyProfile()
        
        // Update UserDefaults for faster future loads
        UserDefaults.standard.set(hasProfile, forKey: "hasClaimedProfile")
        
        // Set the initial tab
        tabState.initializeWithDefaultTab(hasProfile: hasProfile)
    }
}
