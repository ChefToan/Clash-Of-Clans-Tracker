// PlayerStatsView.swift
import SwiftUI

struct PlayerStatsView: View {
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
            Text("PLAYER STATS")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
            
            // Stats list
            VStack(spacing: 0) {
                StatRow(label: "Level", value: "\(player.expLevel)", showDivider: true)
                StatRow(label: "War Stars", value: formatNumber(player.warStars), showDivider: true)
                StatRow(label: "Donations", value: formatNumber(player.donations), showDivider: true)
                StatRow(label: "Donations Received", value: formatNumber(player.donationsReceived), showDivider: true)
                StatRow(label: "Defense Wins", value: formatNumber(player.defenseWins), showDivider: true)
                StatRow(label: "Capital Contributions", value: formatNumber(player.clanCapitalContributions),
                       showDivider: player.warPreference != nil)
                
                if let warPreference = player.warPreference {
                    StatRow(label: "War Preference", value: warPreference.capitalized, showDivider: false)
                }
            }
            .background(Constants.cardBackground)
        }
        .cornerRadius(12)
    }
    
    private func formatNumber(_ number: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                    .font(.body)
                
                Spacer()
                
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            if showDivider {
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
    }
}
