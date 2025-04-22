// EnhancedImageViewer.swift
import SwiftUI

// Enhanced version of the existing code in EnhancedImageViewer.swift
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
    @State private var draggedOffscreen = false
    
    // For context menu
    @State private var showContextMenu = false
    @State private var currentUIImage: UIImage? = nil
    
    // For drag to dismiss logic
    private let dismissThreshold: CGFloat = 200
    private let opacityFactor: CGFloat = 0.005
    
    // For hint text
    @State private var showHint = true
    
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
                    // Use cached image if available, otherwise load from URL
                    if let image = cachedImage {
                        // Display cached image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: draggedOffscreen)
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
                                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: draggedOffscreen)
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
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            // Only adjust scale when we're not dragging offscreen and context menu not showing
                            if !draggedOffscreen && !showContextMenu {
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
                .opacity(showContextMenu ? 0 : (backgroundOpacity * 0.8))
                
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
                    .opacity(scale > 1.01 && !showContextMenu ? (backgroundOpacity * 0.8) : 0)
                    .animation(.easeInOut(duration: 0.2), value: scale > 1.01)
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
            // Apply drag gesture to the entire ZStack
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Don't handle drag when context menu is showing
                        if showContextMenu {
                            return
                        }
                        
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
                        // Don't handle drag end when context menu is showing
                        if showContextMenu {
                            return
                        }
                        
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
        }
        .transition(.opacity)
        .statusBar(hidden: true)
        .onAppear {
            // Auto-hide hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showHint = false
                }
            }
        }
    }
}
