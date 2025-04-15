// TrophyProgressionView.swift
import SwiftUI

struct TrophyProgressionView: View {
    let player: Player
    private let apiService = APIService()
    @State private var chartURL: URL? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
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
                        .frame(height: 180) // Reduced minimum height when loading
                } else if let url = chartURL {
                    // Chart image display
                    ZStack {
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
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
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
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                            @unknown default:
                                Text("Unknown error")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
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
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
        .onAppear {
            loadChart()
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let url = chartURL {
                EnhancedImageViewer(imageURL: url, isPresented: $showFullScreenImage)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private func loadChart() {
        isLoading = true
        errorMessage = nil
        
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

// Enhanced image viewer with Twitter-like UX
struct EnhancedImageViewer: View {
    let imageURL: URL
    @Binding var isPresented: Bool
    
    // Gesture state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var backgroundOpacity: Double = 1.0
    @State private var draggedOffscreen = false
    
    // For drag to dismiss logic
    private let dismissThreshold: CGFloat = 200
    private let opacityFactor: CGFloat = 0.005
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.opacity(backgroundOpacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if scale <= 1.01 {  // Only dismiss on tap if not zoomed in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                backgroundOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }
                    }
                
                // Image container
                ZStack {
                    // Main image
                    AsyncImage(url: imageURL) { phase in
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
                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: draggedOffscreen)
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
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                // Only adjust scale when we're not dragging offscreen
                                if !draggedOffscreen {
                                    let delta = value / lastScale
                                    lastScale = value
                                    
                                    // Limit min/max scale with dampening when exceeding limits
                                    let proposedScale = scale * delta
                                    if proposedScale < 1.0 {
                                        scale = 1.0 + (proposedScale - 1.0) * 0.5
                                    } else if proposedScale > 4.0 {
                                        scale = 4.0 + (proposedScale - 4.0) * 0.5
                                    } else {
                                        scale = proposedScale
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Snap back to limits if needed
                                withAnimation(.interpolatingSpring(stiffness: 230, damping: 22)) {
                                    scale = max(1.0, min(scale, 4.0))
                                }
                                lastScale = 1.0
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let dragAmount = value.translation
                                
                                // Special handling for drag-to-dismiss when not zoomed in
                                if scale <= 1.01 {
                                    let verticalDrag = abs(dragAmount.height)
                                    draggedOffscreen = verticalDrag > dismissThreshold
                                    
                                    // Adjust background opacity based on drag amount
                                    backgroundOpacity = 1.0 - (verticalDrag * opacityFactor)
                                    
                                    // During vertical drag, allow movement but with resistance
                                    offset = CGSize(
                                        width: dragAmount.width,
                                        height: dragAmount.height
                                    )
                                } else {
                                    // When zoomed in, limit drag to prevent image from getting lost
                                    let imageSize = geometry.size
                                    let scaledWidth = imageSize.width * scale
                                    let scaledHeight = imageSize.height * scale
                                    
                                    // Calculate bounds to keep at least 1/3 of the image visible
                                    let horizontalLimit = max(0, (scaledWidth - imageSize.width) / 2) + imageSize.width / 3
                                    let verticalLimit = max(0, (scaledHeight - imageSize.height) / 2) + imageSize.height / 3
                                    
                                    // Add last offset to get total position
                                    let newX = lastOffset.width + dragAmount.width
                                    let newY = lastOffset.height + dragAmount.height
                                    
                                    // Apply limits with damping when exceeding
                                    offset = CGSize(
                                        width: max(-horizontalLimit, min(horizontalLimit, newX)),
                                        height: max(-verticalLimit, min(verticalLimit, newY))
                                    )
                                }
                            }
                            .onEnded { value in
                                // Check if should dismiss
                                if scale <= 1.01 && abs(value.translation.height) > dismissThreshold {
                                    // Continue the dismissal animation
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = CGSize(
                                            width: offset.width,
                                            height: offset.height * 2
                                        )
                                        backgroundOpacity = 0
                                    }
                                    
                                    // Actually dismiss after animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isPresented = false
                                    }
                                    return
                                }
                                
                                // If not dismissing, handle normal gesture end
                                if scale <= 1.01 {
                                    // If not zoomed, reset position with animation
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        offset = .zero
                                        backgroundOpacity = 1.0
                                        draggedOffscreen = false
                                    }
                                    lastOffset = .zero
                                } else {
                                    // If zoomed, store the offset for next drag
                                    lastOffset = offset
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to zoom in/out
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if scale > 1.01 {
                                // Reset zoom
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                // Zoom to 2x
                                scale = 2.0
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                backgroundOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(20)
                                .contentShape(Rectangle())
                        }
                    }
                    
                    Spacer()
                }
                .opacity(backgroundOpacity * 0.8)
                
                // Reset button (only visible when zoomed)
                VStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(20)
                            .contentShape(Rectangle())
                    }
                    .opacity(scale > 1.01 ? (backgroundOpacity * 0.8) : 0)
                    .animation(.easeInOut(duration: 0.2), value: scale > 1.01)
                }
            }
        }
        .transition(.opacity)
        .statusBar(hidden: true)
    }
}
