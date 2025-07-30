// TrophyChartView.swift
import SwiftUI
import Kingfisher

struct TrophyChartView: View {
    let playerTag: String
    @State private var showFullScreen = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var retryCount = 0
    @State private var lastLoadTime = Date()
    @State private var loadingTimer: Timer?
    
    private let loadingTimeout: TimeInterval = 10.0 // 10 seconds timeout
    
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
                    if hasError {
                        // Error state - only show when there's an error
                        VStack(spacing: 10) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Failed to load chart")
                                .foregroundColor(.secondary)
                            
                            Button {
                                HapticManager.shared.lightImpactFeedback()
                                loadingTimer?.invalidate()
                                hasError = false
                                isLoading = true
                                retryCount += 1
                                startLoadingTimer()
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
                    } else {
                        // Chart or loading state
                        KFImage(url)
                            .setProcessor(DefaultImageProcessor())
                            .cacheOriginalImage()
                            .diskCacheExpiration(.seconds(300))
                            .memoryCacheExpiration(.seconds(300))
                            .placeholder {
                                if isLoading {
                                    VStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.blue))
                                            .scaleEffect(1.2)
                                        Text("Loading chart...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 8)
                                    }
                                } else {
                                    EmptyView()
                                }
                            }
                            .onSuccess { _ in
                                loadingTimer?.invalidate()
                                loadingTimer = nil
                                isLoading = false
                                hasError = false
                                lastLoadTime = Date()
                            }
                            .onFailure { _ in
                                loadingTimer?.invalidate()
                                loadingTimer = nil
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
            // Start loading timer only if we're loading
            if isLoading && !hasError {
                startLoadingTimer()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            loadingTimer?.invalidate()
            loadingTimer = nil
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let url = chartURL {
                ImageViewer(url: url, isPresented: $showFullScreen)
            }
        }
    }
    
    private func startLoadingTimer() {
        loadingTimer = Timer.scheduledTimer(withTimeInterval: loadingTimeout, repeats: false) { _ in
            // If still loading after timeout, show error state
            if isLoading && !hasError {
                isLoading = false
                hasError = true
            }
        }
    }
}
