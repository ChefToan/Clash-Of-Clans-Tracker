// LeagueInfoView.swift
import SwiftUI

struct LeagueInfoView: View {
    let player: PlayerEssentials
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("LEAGUE INFO")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)

            // Content
            VStack(spacing: 20) {
                // Current League and All-time Best Side by Side
                HStack(spacing: 20) {
                    // Current League - Left Side
                    VStack(spacing: 12) {
                        Text("Current League")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if let leagueIcon = getLeagueIcon(for: player.league) {
                            Image(leagueIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        } else {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 45))
                                .foregroundColor(Constants.purple)
                        }
                        
                        if let league = player.league {
                            Text(league.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)

                            Text(formatNumber(player.trophies))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Vertical Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 100)
                    
                    // All-time Best - Right Side
                    VStack(spacing: 12) {
                        Text("All-time Best")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        if let bestLeagueIcon = getBestLeagueIcon(trophies: player.bestTrophies) {
                            Image(bestLeagueIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        } else {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 45))
                                .foregroundColor(Constants.purple.opacity(0.8))
                        }

                        if let bestLeagueName = getBestLeagueName(trophies: player.bestTrophies) {
                            Text(bestLeagueName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)

                            Text(formatNumber(player.bestTrophies))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Current Rankings (Legends) - Only show if in legends
                if let legends = player.legends {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Text("Current Rankings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        HStack(spacing: 40) {
                            VStack(spacing: 6) {
                                Text("Global")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let rank = legends.globalRank {
                                    Text("#\(formatNumber(rank))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Unranked")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            VStack(spacing: 6) {
                                Text("Local")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let rank = legends.localRank {
                                    Text("#\(formatNumber(rank))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Unranked")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Constants.cardBackground)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }

    private func formatNumber(_ number: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func getLeagueIcon(for league: LeagueInfo?) -> String? {
        guard let league = league else { return nil }
        
        let leagueName = league.name.lowercased()
        
        if leagueName.contains("bronze") {
            return "league_bronze"
        } else if leagueName.contains("silver") {
            return "league_silver"
        } else if leagueName.contains("gold") {
            return "league_gold"
        } else if leagueName.contains("crystal") {
            return "league_crystal"
        } else if leagueName.contains("master") {
            return "league_master"
        } else if leagueName.contains("champion") {
            return "league_champion"
        } else if leagueName.contains("titan") {
            return "league_titan"
        } else if leagueName.contains("legend") {
            return "league_legend"
        } else if leagueName.contains("unranked") {
            return "league_unranked"
        }
        
        return nil
    }
    
    private func getBestLeagueIcon(trophies: Int) -> String? {
        switch trophies {
        case 5000...:
            return "league_legend"
        case 4100..<5000:
            return "league_titan"
        case 3200..<4100:
            return "league_champion"
        case 2600..<3200:
            return "league_master"
        case 2000..<2600:
            return "league_crystal"
        case 1400..<2000:
            return "league_gold"
        case 800..<1400:
            return "league_silver"
        case 400..<800:
            return "league_bronze"
        default:
            return "league_unranked"
        }
    }
    
    private func getBestLeagueName(trophies: Int) -> String? {
        switch trophies {
        case 5000...:
            return "Legend League"
        case 4100..<5000:
            return "Titan League"
        case 3200..<4100:
            return "Champion League"
        case 2600..<3200:
            return "Master League"
        case 2000..<2600:
            return "Crystal League"
        case 1400..<2000:
            return "Gold League"
        case 800..<1400:
            return "Silver League"
        case 400..<800:
            return "Bronze League"
        default:
            return "Unranked"
        }
    }
}
