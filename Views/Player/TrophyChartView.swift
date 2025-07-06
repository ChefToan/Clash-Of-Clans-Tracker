// TrophyChartView.swift
import SwiftUI
import Kingfisher

struct TrophyChartView: View {
    let playerTag: String
    @State private var showFullScreen = false
    @State private var hasError = false
    @State private var isLoading = true
    @State private var retryCount = 0
    @State private var lastLoadTime = Date()
    
    private var chartURL: URL? {
        APIService.shared.getChartURL(tag: playerTag)
    }
    
    // Configure Kingfisher cache for 5 minutes
    private var cacheOptions: KingfisherOptionsInfo {
        let cacheExpiration = StorageExpiration.seconds(300) // 5 minutes
        return [
            .cacheMemoryOnly, // Use memory cache only for quick access
            .diskCacheExpiration(cacheExpiration),
            .memoryCacheExpiration(cacheExpiration),
            .forceRefresh // Force refresh if cache is expired
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TROPHY PROGRESSION")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
            }
            
            // Fixed height container for chart
            ZStack {
                // Background
                Color(UIColor.secondarySystemBackground)
                
                if let url = chartURL {
                    KFImage(url)
                        .setProcessor(DefaultImageProcessor()) // Ensure fresh processing
                        .cacheOriginalImage() // Cache the original image
                        .diskCacheExpiration(.seconds(300)) // 5 minute disk cache
                        .memoryCacheExpiration(.seconds(300)) // 5 minute memory cache
                        .placeholder {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.blue))
                                    .scaleEffect(1.2)
                                Text("Loading chart...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        .onSuccess { _ in
                            isLoading = false
                            hasError = false
                            lastLoadTime = Date()
                        }
                        .onFailure { _ in
                            isLoading = false
                            hasError = true
                        }
                        .fade(duration: 0.3)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture {
                            HapticManager.shared.lightImpactFeedback()
                            showFullScreen = true
                        }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Invalid player tag")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Error state
                if hasError && !isLoading {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Failed to load chart")
                            .foregroundColor(.secondary)
                        
                        Button {
                            HapticManager.shared.lightImpactFeedback()
                            retryCount += 1
                            isLoading = true
                            hasError = false
                        } label: {
                            Text("Retry")
                                .font(.caption)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Constants.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Tap hint overlay (only show when image is loaded)
                if !isLoading && !hasError && chartURL != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption2)
                                Text("Tap to view full screen")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .padding(8)
                        }
                    }
                }
            }
            .frame(height: 250) // Fixed height
            .clipped() // Ensure content doesn't overflow
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .id(retryCount) // Force reload on retry
        .onAppear {
            // Check if we need to refresh based on last load time
            if Date().timeIntervalSince(lastLoadTime) > 300 { // 5 minutes
                retryCount += 1 // Force reload
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let url = chartURL {
                ImageViewer(url: url, isPresented: $showFullScreen)
            }
        }
    }
}
