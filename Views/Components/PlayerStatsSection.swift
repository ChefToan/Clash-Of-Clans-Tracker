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
                // Level
                SimpleStatRow(
                    label: "Level",
                    value: "\(player.expLevel)",
                    iconColor: Constants.blue
                )
                
                // Capital Contribution
                SimpleStatRow(
                    label: "Capital Contribution",
                    value: player.clanCapitalContributions.formatted,
                    iconColor: Color.gray
                )
                
                // Attacks Won
                SimpleStatRow(
                    label: "Attacks Won",
                    value: "\(player.attackWins)",
                    iconColor: .clear
                )
                
                // Defenses Won
                SimpleStatRow(
                    label: "Defenses Won",
                    value: "\(player.defenseWins)",
                    iconColor: .clear
                )
                
                // War Stars Won
                SimpleStatRow(
                    label: "War Stars Won",
                    value: "\(player.warStars)",
                    iconColor: .clear
                )
                
                // Donations
                SimpleStatRow(
                    label: "Donations",
                    value: "\(player.donations)",
                    iconColor: Constants.green
                )
                
                // Donations Received
                SimpleStatRow(
                    label: "Donations Received",
                    value: "\(player.donationsReceived)",
                    iconColor: Constants.red
                )
            }
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
    }
}
