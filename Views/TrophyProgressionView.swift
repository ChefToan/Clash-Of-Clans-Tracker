// TrophyProgressionView.swift
import SwiftUI

struct TrophyProgressionView: View {
    let player: Player
    private let apiService = APIService()
    @State private var chartURL: URL? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var imageSize: CGSize = .zero
    @State private var showFullScreenImage = false
    
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
                                        .onTapGesture {
                                            withAnimation {
                                                showFullScreenImage = true
                                            }
                                        }
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
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let url = chartURL {
                ZoomedImageView(url: url, isPresented: $showFullScreenImage)
            }
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

struct ZoomedImageView: View {
    let url: URL
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Min scale is 1.0 to prevent zooming out smaller than original
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Image
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // Only update if we're actively changing the scale
                                    if abs(value - lastScale) > 0.01 {
                                        let delta = value / lastScale
                                        lastScale = value
                                        
                                        // Calculate new scale with limits
                                        let newScale = scale * delta
                                        scale = min(max(newScale, minScale), maxScale)
                                    }
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    
                                    // Smooth animation back to min scale if needed
                                    if scale < minScale {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = minScale
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Use direct manipulation for smoother dragging
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        lastOffset = offset
                                    }
                                }
                        )
                case .failure:
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("Failed to load image")
                            .foregroundColor(.white)
                    }
                @unknown default:
                    Text("Unknown error")
                        .foregroundColor(.white)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
            }
            
            // Reset zoom button
            VStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding()
                }
                .opacity(scale != 1.0 || offset != .zero ? 1.0 : 0.0)
                .padding(.bottom, 20)
            }
        }
        // Use high performance rendering for smoother zoom
        .drawingGroup()
    }
}
