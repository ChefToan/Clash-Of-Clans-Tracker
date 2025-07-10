// PlayerHeaderView.swift
import SwiftUI
import Kingfisher

struct PlayerHeaderView: View {
    let player: PlayerEssentials

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("PLAYER INFO")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)

            // Content
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    // Player Info
                    VStack(spacing: 8) {
                        Text(player.playerName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)

                        Text(player.playerTag)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)

                        // Town Hall Icon
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
                    .frame(maxWidth: .infinity)

                    // Clan Info
                    if let clan = player.clan {
                        VStack(spacing: 8) {
                            Text(clan.name ?? "Unknown Clan")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)

                            Text(clan.tag ?? "#UNKNOWN")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            if let badgeURLString = clan.badgeUrls?.medium,
                               let url = URL(string: badgeURLString) {
                                KFImage(url)
                                    .placeholder {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                            } else {
                                Image(systemName: "shield.slash.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }

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
                        .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Constants.cardBackground)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
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


// Simplified and more reliable scrolling text component
struct AutoScrollingText: View {
    let text: String
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var shouldScroll = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Invisible text to measure width
                Text(text)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                    checkIfShouldScroll()
                                }
                                .onChange(of: text) { _, _ in
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                    checkIfShouldScroll()
                                }
                                .onChange(of: geometry.size.width) { _, newWidth in
                                    containerWidth = newWidth
                                    checkIfShouldScroll()
                                }
                        }
                    )
                
                // Visible scrolling text
                if shouldScroll {
                    HStack(spacing: 40) {
                        Text(text)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        Text(text)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .offset(x: offset)
                    .onAppear {
                        startScrolling()
                    }
                } else {
                    // Centered text when it fits
                    Text(text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .clipped()
        }
    }
    
    private func checkIfShouldScroll() {
        shouldScroll = textWidth > containerWidth
        if !shouldScroll {
            offset = 0
        }
    }
    
    private func startScrolling() {
        guard shouldScroll else { return }
        
        offset = 0
        
        // Start animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                offset = -(textWidth + 40)
            }
        }
    }
}

// Alternative even simpler implementation
struct SimpleAutoScrollText: View {
    let text: String
    
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Text(text + "     " + text)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .offset(x: animate ? -geometry.size.width : 0)
                        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: animate)
                }
            }
            .disabled(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animate = true
                }
            }
        }
        .clipped()
    }
}
