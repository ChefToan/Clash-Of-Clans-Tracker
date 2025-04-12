// TrophyProgressionView.swift
import SwiftUI

struct TrophyProgressionView: View {
    let player: Player
    private let apiService = APIService()
    @State private var chartURL: URL? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("TROPHY PROGRESSION")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            
            // Content
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(height: 100) // Minimum height when loading
                } else if let url = chartURL {
                    // Using GeometryReader to get container size
                    GeometryReader { geometry in
                        ZStack {
                            Color.clear // Used for sizing
                            
                            AsyncImage(url: url, transaction: Transaction(animation: .easeIn)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(
                                            GeometryReader { imageGeometry in
                                                Color.clear
                                                    .onAppear {
                                                        // Set the size immediately
                                                        imageSize = imageGeometry.size
                                                        
                                                        // Use a slight delay to ensure accurate size after layout
                                                        DispatchQueue.main.async {
                                                            imageSize = imageGeometry.size
                                                        }
                                                    }
                                            }
                                        )
                                case .failure:
                                    VStack {
                                        Image(systemName: "chart.line.downtrend.xyaxis")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        Text("Failed to load chart")
                                            .foregroundColor(.gray)
                                        
                                        Button(action: {
                                            loadChart()
                                        }) {
                                            Text("Retry")
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                                .background(Constants.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(Constants.buttonCornerRadius)
                                        }
                                        .padding(.top, 10)
                                    }
                                    .frame(height: 100) // Minimum height when error
                                @unknown default:
                                    Text("Unknown error")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(4) // Reduced padding to maximize chart size
                        }
                    }
                    // Adjust container height based on content
                    .frame(height: imageSize.height > 0 ? imageSize.height + 10 : 200)
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            loadChart()
                        }) {
                            Text("Retry")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Constants.blue)
                                .foregroundColor(.white)
                                .cornerRadius(Constants.buttonCornerRadius)
                        }
                        .padding(.top, 10)
                    }
                    .frame(height: 100) // Minimum height when error
                }
            }
            .padding()
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
        .onAppear {
            loadChart()
        }
    }
    
    private func loadChart() {
        isLoading = true
        errorMessage = nil
        imageSize = .zero
        
        DispatchQueue.main.async {
            if let url = apiService.getPlayerChartImageURL(tag: player.tag) {
                self.chartURL = url
                self.isLoading = false
            } else {
                self.errorMessage = "Invalid player tag format"
                self.isLoading = false
            }
        }
    }
}
