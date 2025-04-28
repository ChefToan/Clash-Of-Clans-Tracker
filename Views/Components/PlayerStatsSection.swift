// PlayerStatsSection.swift
import SwiftUI

struct PlayerStatsSection: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("PLAYER STATS")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            
            // Content
            VStack(spacing: 0) {
                // Level - with icon
                SimpleStatRow(
                    label: "Level",
                    value: "\(player.expLevel)",
                    iconImage: "icon_exp"
                )
                
                // Capital Contribution - with icon
                SimpleStatRow(
                    label: "Capital Contribution",
                    value: player.clanCapitalContributions.formatted
                )
                
                // Attacks Won
                SimpleStatRow(
                    label: "Attacks Won",
                    value: "\(player.attackWins)"
                )
                
                // Defenses Won
                SimpleStatRow(
                    label: "Defenses Won",
                    value: "\(player.defenseWins)"
                )
                
                // War Stars Won
                SimpleStatRow(
                    label: "War Stars Won",
                    value: "\(player.warStars)"
                )
                
                // Donations
                SimpleStatRow(
                    label: "Donations",
                    value: "\(player.donations)"
                )
                
                // Donations Received
                SimpleStatRow(
                    label: "Donations Received",
                    value: "\(player.donationsReceived)"
                )
                
                // Add empty space at the bottom if there are no stats to ensure minimum height
                if player.donations == 0 && player.donationsReceived == 0 &&
                   player.attackWins == 0 && player.defenseWins == 0 &&
                   player.warStars == 0 && player.clanCapitalContributions == 0 {
                    Spacer()
                        .frame(height: 20)
                }
            }
            .padding(.vertical, 5) // Consistent vertical padding
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
    }
}
