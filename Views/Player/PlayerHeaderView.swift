// PlayerHeaderView.swift
import SwiftUI
import Kingfisher

struct PlayerHeaderView: View {
    let player: PlayerEssentials
    
    var body: some View {
        VStack(spacing: 0) {
            // Content with gradient background
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "#2d3561"), Color(hex: "#1a1a2e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                HStack(spacing: 20) {
                    // Player info
                    VStack(spacing: 8) {
                        Text(player.playerName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(player.playerTag)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Town Hall
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 90, height: 90)
                            
                            Image("th\(player.townHallLevel)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text("TH\(player.townHallLevel)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(4)
                                        .offset(y: 35)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Clan info
                    if let clan = player.clan {
                        VStack(spacing: 8) {
                            Text(clan.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(clan.tag)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            KFImage(URL(string: clan.badgeUrls.medium))
                                .placeholder {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                .fade(duration: 0.25)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                            
                            if let role = player.role {
                                Text(formatRole(role))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Constants.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    private func formatRole(_ role: String) -> String {
        switch role.lowercased() {
        case "coleader": return "Co-Leader"
        case "admin", "elder": return "Elder"
        case "leader": return "Leader"
        default: return "Member"
        }
    }
}
