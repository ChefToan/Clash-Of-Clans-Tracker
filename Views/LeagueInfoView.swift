// LeagueInfoView.swift
import SwiftUI

struct LeagueInfoView: View {
    let player: Player
    let rankingsData: PlayerRankings?
    @State private var isLoadingRankings = true
    @State private var loadingTimeoutTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Updated for consistent appearance
            Text("LEAGUE INFO")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Constants.headerTextColor)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Constants.headerBackground)
            
            // Content
            VStack(spacing: 0) {
                if let league = player.league {
                    // Current League section
                    Text("Current League")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 15)
                    
                    // League Icon
                    LeagueIconView(league: league)
                        .padding(.vertical, 8)
                    
                    Text(league.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Trophy Count
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Constants.yellow)
                            .font(.title)
                        
                        Text("\(player.trophies)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.yellow)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Current Rankings section
                    Text("Current Rankings")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    HStack(spacing: 40) {
                        // Global Rank
                        VStack(spacing: 8) {
                            Text("Global:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            // Show loading or rank
                            if isLoadingRankings {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .frame(height: 26)
                            } else if let rankings = rankingsData, let globalRank = rankings.globalRank, globalRank > 0 {
                                Text("#\(globalRank)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Constants.dynamicColor(light: .black, dark: .white))
                            } else {
                                // Only show "Unranked" if we've received data and confirmed there's no rank
                                // or if loading timed out
                                Text("Unranked")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Constants.dynamicColor(light: .black, dark: .white))
                            }
                        }
                        
                        // Local Rank
                        VStack(spacing: 8) {
                            Text("Local:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            // Show loading or rank
                            if isLoadingRankings {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .frame(height: 26)
                            } else if let rankings = rankingsData, let localRank = rankings.localRank, localRank > 0 {
                                Text("#\(localRank)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Constants.dynamicColor(light: .black, dark: .white))
                            } else {
                                // Only show "Unranked" if we've received data and confirmed there's no rank
                                // or if loading timed out
                                Text("Unranked")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Constants.dynamicColor(light: .black, dark: .white))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // All-time best section
                    Text("All time best")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                    
                    // Get the all-time best league based on trophy count
                    let bestLeague = getLeagueFromTrophies(player.bestTrophies)
                    
                    // Best League Icon
                    Image(bestLeague.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .padding(.vertical, 8)
                    
                    Text(bestLeague.name)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Constants.yellow)
                        
                        Text("\(player.bestTrophies)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.yellow)
                    }
                    .padding(.bottom, 15)
                } else {
                    // Unranked view styled to match the league view
                    // Current League section
                    Text("Current League")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 15)
                    
                    // Unranked League Icon
                    Image("league_unranked")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .padding(.vertical, 8)
                    
                    Text("Unranked")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Trophy Count
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Constants.yellow)
                            .font(.title)
                        
                        Text("\(player.trophies)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.yellow)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Current Rankings
                    Text("Current Rankings")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    // Display unranked for both global and local
                    HStack(spacing: 40) {
                        // Global Rank
                        VStack(spacing: 8) {
                            Text("Global:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Unranked")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Local Rank
                        VStack(spacing: 8) {
                            Text("Local:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Unranked")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // All-time best section
                    Text("All time best")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                    
                    // Get the all-time best league based on trophy count
                    let bestLeague = getLeagueFromTrophies(player.bestTrophies)
                    
                    // Best League Icon
                    Image(bestLeague.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .padding(.vertical, 8)
                    
                    Text(bestLeague.name)
                        .font(.headline)
                    
                    // Best trophy count
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Constants.yellow)
                        
                        Text("\(player.bestTrophies)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.yellow)
                    }
                    .padding(.bottom, 15)
                }
            }
            .padding(.horizontal, 0) // Remove horizontal padding to match header width
            .background(Constants.cardBackground)
            .onAppear {
                // Check if we already have data
                if rankingsData != nil {
                    isLoadingRankings = false
                    return
                }
                
                // Start with loading state if in Legend League
                if player.league?.name.contains("Legend") == true {
                    isLoadingRankings = true
                    
                    // Create a timer that will automatically stop the loading state after 5 seconds
                    loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                        if isLoadingRankings {
                            isLoadingRankings = false
                            print("Rankings loading timed out after 5 seconds")
                        }
                    }
                } else {
                    // Not in Legend League, no need to load
                    isLoadingRankings = false
                }
            }
            .onDisappear {
                // Clean up the timer when view disappears
                loadingTimeoutTimer?.invalidate()
                loadingTimeoutTimer = nil
            }
        }
        .background(Constants.background)
        .cornerRadius(Constants.cornerRadius)
    }
    
    // Structure to hold league information
    struct LeagueInfo {
        let name: String
        let iconName: String
    }
    
    // Function to determine league based on trophy count - simplified to group leagues
    func getLeagueFromTrophies(_ trophies: Int) -> LeagueInfo {
        switch trophies {
        case 0..<400:
            return LeagueInfo(name: "Unranked", iconName: "league_unranked")
        case 400..<800:
            return LeagueInfo(name: "Bronze", iconName: "league_bronze")
        case 800..<1400:
            return LeagueInfo(name: "Silver", iconName: "league_silver")
        case 1400..<2000:
            return LeagueInfo(name: "Gold", iconName: "league_gold")
        case 2000..<2600:
            return LeagueInfo(name: "Crystal", iconName: "league_crystal")
        case 2600..<3200:
            return LeagueInfo(name: "Master", iconName: "league_master")
        case 3200..<4100:
            return LeagueInfo(name: "Champion", iconName: "league_champion")
        case 4100..<5000:
            return LeagueInfo(name: "Titan", iconName: "league_titan")
        default:
            return LeagueInfo(name: "Legend", iconName: "league_legend")
        }
    }
}
