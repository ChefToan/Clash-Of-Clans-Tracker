//  PlayerProfileView.swift
import SwiftUI

struct PlayerProfileView: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 0) {
            Text("PLAYER PROFILE")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            
            HStack(spacing: 20) {
                // Left side - Player info
                VStack(alignment: .center, spacing: 10) {
                    Text(player.name.uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(player.tag)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Town Hall placeholder (will be replaced with actual icon)
                    TownHallIconView(level: player.townHallLevel)
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Clan info
                if let clan = player.clan {
                    VStack(alignment: .center, spacing: 10) {
                        Text(clan.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(clan.tag)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Clan Badge from API
                        ClanBadgeView(clan: clan)
                        
                        Text(player.role ?? "Member")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Constants.blue)
                            .cornerRadius(Constants.buttonCornerRadius)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 10)
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
    }
}
