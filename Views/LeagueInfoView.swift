// LeagueInfoView.swift
import SwiftUI

struct LeagueInfoView: View {
    let player: Player
    let rankingsData: PlayerRankings?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("LEAGUE INFO")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            
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
                        .padding(.vertical, 10)
                    
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
                    .padding(.vertical, 10)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Current Rankings section
                    Text("Current Rankings")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 15)
                        .padding(.bottom, 10)
                    
                    HStack(spacing: 40) {
                        // Global Rank
                        VStack(spacing: 8) {
                            Text("Global:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            if let rankings = rankingsData, let globalRank = rankings.globalRank, globalRank > 0 {
                                Text("#\(globalRank)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("Unranked")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Local Rank
                        VStack(spacing: 8) {
                            Text("Local:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            if let rankings = rankingsData, let localRank = rankings.localRank, localRank > 0 {
                                Text("#\(localRank)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("Unranked")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // All-time best section
                    Text("All time best")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 15)
                    
                    // League Icon (same as current league)
                    LeagueIconView(league: league)
                        .padding(.vertical, 10)
                    
                    Text(league.name)
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
                    Text("Unranked")
                        .font(.headline)
                        .padding()
                }
            }
            .padding(.horizontal)
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
    }
}
