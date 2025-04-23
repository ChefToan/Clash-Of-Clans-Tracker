// EnhancedImageViewer.swift
import SwiftUI

struct EnhancedImageViewer: View {
    var imageURL: URL? = nil
    var cachedImage: UIImage? = nil
    @Binding var isPresented: Bool
    
    // Gesture state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var backgroundOpacity: Double = 1.0
    @State private var isDragging = false
    
    // For context menu
    @State private var showContextMenu = false
    @State private var currentUIImage: UIImage? = nil
    
    // For drag to dismiss logic
    private let dismissThreshold: CGFloat = 150
    
    // For hint text
    @State private var showHint = true
    
    // For device orientation
    @State private var isPortrait = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.opacity(backgroundOpacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if scale <= 1.01 {  // Only dismiss on tap if not zoomed in
                            dismissViewer()
                        }
                    }
                
                // Image container
                Group {
                    if let image = cachedImage {
                        // Display cached image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .onTapGesture(count: 2) {
                                // Double tap to zoom in/out
                                if scale <= 1.01 {
                                    // Zoom in to 2.5x with standard animation
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        scale = 2.5
                                    }
                                } else {
                                    // Reset to normal view
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                            .onLongPressGesture {
                                // Trigger haptic feedback
                                HapticManager.shared.mediumImpactFeedback()
                                
                                currentUIImage = image
                                withAnimation {
                                    showContextMenu = true
                                }
                            }
                    } else if let url = imageURL {
                        // Fallback to loading from URL
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
                                    .onTapGesture(count: 2) {
                                        // Double tap to zoom in/out
                                        if scale <= 1.01 {
                                            // Zoom in to 2.5x with standard animation
                                            withAnimation(.easeOut(duration: 0.25)) {
                                                scale = 2.5
                                            }
                                        } else {
                                            // Reset to normal view
                                            withAnimation(.easeOut(duration: 0.25)) {
                                                scale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    }
                                    .onLongPressGesture {
                                        // Trigger haptic feedback
                                        HapticManager.shared.mediumImpactFeedback()
                                        
                                        if let uiImage = image.asUIImage() {
                                            currentUIImage = uiImage
                                            withAnimation {
                                                showContextMenu = true
                                            }
                                        }
                                    }
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
                    } else {
                        // Neither cached image nor URL is available
                        Text("No image available")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            dismissViewer()
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
                .opacity(showContextMenu ? 0 : (backgroundOpacity * 0.8))
                
                // Reset button (only visible when zoomed)
                VStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.25)) {
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
                    .opacity(scale > 1.01 && !showContextMenu ? (backgroundOpacity * 0.8) : 0)
                }
                
                // Hint text at bottom
                VStack {
                    Spacer()
                    
                    Text("Long press to save or copy image")
                        .font(.footnote)
                        .padding(10)
                        .foregroundColor(.white.opacity(0.8))
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                        .opacity(showHint ? 1.0 : 0.0)
                }
                .opacity(showContextMenu ? 0 : 1)
                
                // Show custom context menu when long pressed
                if showContextMenu, let image = currentUIImage {
                    CustomContextMenu(image: image, isPresented: $showContextMenu)
                        .zIndex(100)
                }
            }
            // Split gesture handling to separate functions with simplified animations
            .gesture(dragGesture(geometry: geometry))
            .gesture(magnificationGesture())
        }
        .transition(.opacity)
        .statusBar(hidden: true)
        .onAppear {
            // Detect orientation initially
            updateOrientation()
            
            // Auto-hide hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showHint = false
                }
            }
        }
        .onChange(of: UIDevice.current.orientation) { _ in
            updateOrientation()
        }
    }
    
    // Simple function to dismiss the viewer
    private func dismissViewer() {
        withAnimation(.easeInOut(duration: 0.2)) {
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
    
    // Separate drag gesture with simplified calculations
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { value in
                if showContextMenu { return }
                
                if scale > 1.01 {
                    // Handle panning when zoomed in
                    let translation = value.translation
                    let imageSize = geometry.size
                    let scaledWidth = imageSize.width * scale
                    let scaledHeight = imageSize.height * scale
                    
                    // Calculate maximum permitted drag limits
                    let horizontalLimit = max(0, (scaledWidth - imageSize.width) / 2)
                    let verticalLimit = max(0, (scaledHeight - imageSize.height) / 2)
                    
                    var newX = lastOffset.width + translation.width
                    var newY = lastOffset.height + translation.height
                    
                    // Apply constraints to keep image centered when smaller than screen
                    if scaledWidth <= imageSize.width { newX = 0 }
                    if scaledHeight <= imageSize.height { newY = 0 }
                    
                    // Apply bounds
                    newX = max(-horizontalLimit, min(horizontalLimit, newX))
                    newY = max(-verticalLimit, min(verticalLimit, newY))
                    
                    // Apply the offset directly without animation
                    offset = CGSize(width: newX, height: newY)
                    
                    isDragging = true
                } else {
                    // Handle dismiss gesture (swipe down to dismiss)
                    let translation = value.translation
                    
                    // Only respond to primarily downward swipes
                    if translation.height > 0 && translation.height > abs(translation.width) {
                        // Apply downward drag directly
                        let dragDistance = translation.height
                        
                        // Update opacity and offset directly
                        backgroundOpacity = max(0.3, 1.0 - (dragDistance / 500))
                        offset = CGSize(
                            width: translation.width * 0.5,
                            height: translation.height
                        )
                    }
                }
            }
            .onEnded { value in
                if showContextMenu { return }
                
                if scale > 1.01 {
                    // End panning when zoomed in
                    let finalVelocity = value.predictedEndLocation.y - value.location.y
                    let velocity = abs(finalVelocity) > 100 ? finalVelocity * 0.1 : 0
                    
                    // Calculate the image bounds
                    let imageSize = geometry.size
                    let scaledWidth = imageSize.width * scale
                    let scaledHeight = imageSize.height * scale
                    let horizontalLimit = max(0, (scaledWidth - imageSize.width) / 2)
                    let verticalLimit = max(0, (scaledHeight - imageSize.height) / 2)
                    
                    // Apply simplified bounds calculation
                    var newX = offset.width
                    var newY = offset.height
                    
                    // Apply constraints
                    if scaledWidth <= imageSize.width { newX = 0 }
                    else { newX = max(-horizontalLimit, min(horizontalLimit, newX)) }
                    
                    if scaledHeight <= imageSize.height { newY = 0 }
                    else { newY = max(-verticalLimit, min(verticalLimit, newY + velocity)) }
                    
                    // Use a simple animation with fixed duration
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = CGSize(width: newX, height: newY)
                    }
                    
                    // Wait for animation to complete before updating last offset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        lastOffset = offset
                        isDragging = false
                    }
                } else {
                    // Handle dismiss gesture end
                    let translation = value.translation
                    
                    // Check if swipe down exceeds dismiss threshold
                    if translation.height > dismissThreshold && translation.height > 0 {
                        // Simple dismiss animation
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = CGSize(width: 0, height: geometry.size.height)
                            backgroundOpacity = 0
                        }
                        
                        // Dismiss after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                        }
                    } else {
                        // Reset position if not dismissing
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = .zero
                            backgroundOpacity = 1.0
                        }
                        lastOffset = .zero
                    }
                }
            }
    }
    
    // Separate magnification gesture with simplified handling
    private func magnificationGesture() -> some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                if showContextMenu { return }
                
                // Simple scaling with fixed limits
                let delta = value / lastScale
                lastScale = value
                
                // Apply scaling directly with clamping
                let newScale = scale * delta
                scale = min(max(newScale, 0.8), 4.0)
            }
            .onEnded { _ in
                if showContextMenu { return }
                
                // Simple animation with fixed duration
                withAnimation(.easeOut(duration: 0.2)) {
                    // Snap to limits
                    if scale < 1.0 {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else if scale > 4.0 {
                        scale = 4.0
                    }
                }
                
                // Reset scale tracking
                lastScale = 1.0
            }
    }
    
    // Update orientation state
    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        isPortrait = orientation.isPortrait || (!orientation.isLandscape && !orientation.isFlat)
    }
}

