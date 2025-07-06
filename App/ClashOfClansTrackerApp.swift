// ClashOfClansTrackerApp.swift
import SwiftUI
import SwiftData
import Network

enum TabSection: Int, CaseIterable {
    case search = 0
    case profile = 1
    case settings = 2
}

@main
struct ClashOfClansTrackerApp: App {
    @StateObject private var dataController = DataController.shared
    @StateObject private var tabState = TabState.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var hasCheckedProfile = false
    @State private var previousTab: TabSection = .search
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabState.selectedTab) {
                NavigationStack {
                    SearchPlayersView()
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Players")
                }
                .tag(TabSection.search)
                
                NavigationStack {
                    MyProfileView()
                }
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("My Profile")
                }
                .tag(TabSection.profile)
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(TabSection.settings)
            }
            .tint(Constants.blue)
            .environment(\.colorScheme, .dark) // Force dark mode
            .modelContainer(dataController.container)
            .environmentObject(tabState)
            .environmentObject(dataController)
            .environmentObject(networkMonitor)
            .task {
                if !hasCheckedProfile {
                    hasCheckedProfile = true
                    // Check if user has a profile saved
                    if await dataController.hasProfile() {
                        // Start at profile tab if they have a saved profile
                        tabState.selectedTab = .profile
                    } else {
                        // Start at search tab if no profile
                        tabState.selectedTab = .search
                    }
                }
            }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                dataController.setOfflineStatus(!isConnected)
            }
            .onChange(of: tabState.selectedTab) { oldValue, newValue in
                // Add haptic feedback when tab changes
                if oldValue != newValue {
                    HapticManager.shared.selectionFeedback()
                }
                previousTab = oldValue
            }
            // Remove the custom swipe gesture - let NavigationStack handle navigation
        }
    }
}

// Tab state management
class TabState: ObservableObject {
    static let shared = TabState()
    @Published var selectedTab: TabSection = .search
    
    private init() {}
    
    func switchToProfile() {
        withAnimation(.spring()) {
            selectedTab = .profile
        }
    }
    
    func switchToSearch() {
        withAnimation(.spring()) {
            selectedTab = .search
        }
    }
    
    func switchToSettings() {
        withAnimation(.spring()) {
            selectedTab = .settings
        }
    }
}

// Network monitoring for offline support
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
