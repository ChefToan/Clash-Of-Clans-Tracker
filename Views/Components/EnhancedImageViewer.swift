// EnhancedImageViewer.swift
import SwiftUI

struct EnhancedImageViewer: View {
    var imageURL: URL? = nil
    var cachedImage: UIImage? = nil
    @Binding var isPresented: Bool
    
    // State
    @State private var backgroundOpacity: Double = 1.0
    @State private var showContextMenu = false
    @State private var currentUIImage: UIImage? = nil
    @State private var showHint = true
    @State private var verticalDragOffset: CGFloat = 0
    @State private var isLoading = true
    @State private var isDragging = false
    @State private var viewSize: CGSize = .zero
    
    // Constants
    private let dismissThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.opacity(backgroundOpacity)
                    .edgesIgnoringSafeArea(.all)
                
                // Image content
                Group {
                    if let image = cachedImage ?? currentUIImage {
                        ZoomableImageView(
                            image: image,
                            onTap: handleTap,
                            onLongPress: handleLongPress,
                            onSwipeDown: handleDismiss
                        )
                        .opacity(isLoading ? 0 : 1)
                        .onAppear {
                            // Load image with slight delay to avoid animation conflict
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withoutAnimation {
                                    isLoading = false
                                }
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
                                Color.clear
                                    .onAppear {
                                        if let uiImage = image.asUIImage() {
                                            withoutAnimation {
                                                currentUIImage = uiImage
                                                isLoading = false
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
                                EmptyView()
                            }
                        }
                    } else {
                        // Fallback text
                        Text("No image available")
                            .foregroundColor(.white)
                    }
                }
                .offset(y: verticalDragOffset)
                .gesture(
                    // Separate DragGesture just for dismissal
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            // Only handle vertical drags for dismissal
                            if !showContextMenu && value.translation.height > 0 {
                                withTransaction(Transaction(animation: nil)) {
                                    isDragging = true
                                    verticalDragOffset = value.translation.height
                                    backgroundOpacity = 1.0 - min(0.8, verticalDragOffset / 500)
                                }
                            }
                        }
                        .onEnded { value in
                            if !showContextMenu && isDragging {
                                if value.translation.height > dismissThreshold {
                                    // Dismiss with animation
                                    withTransaction(Transaction(animation: .easeOut(duration: 0.2))) {
                                        verticalDragOffset = 300
                                        backgroundOpacity = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isPresented = false
                                    }
                                } else {
                                    // Reset position with animation
                                    withTransaction(Transaction(animation: .spring(response: 0.3, dampingFraction: 0.7))) {
                                        verticalDragOffset = 0
                                        backgroundOpacity = 1.0
                                    }
                                }
                                isDragging = false
                            }
                        }
                )
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: handleDismiss) {
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
                if showContextMenu, let image = currentUIImage ?? cachedImage {
                    CustomContextMenu(image: image, isPresented: $showContextMenu)
                        .zIndex(100)
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                // Track size changes (orientation changes)
                viewSize = newSize
            }
        }
        .ignoresSafeArea(.all)
        .statusBar(hidden: true)
        .onAppear {
            // Auto-hide hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showHint = false
                }
            }
        }
        .transition(.opacity)
    }
    
    private func handleTap() {
        if !showContextMenu {
            handleDismiss()
        }
    }
    
    private func handleLongPress() {
        HapticManager.shared.mediumImpactFeedback()
        withAnimation {
            showContextMenu = true
        }
    }
    
    private func handleDismiss() {
        withTransaction(Transaction(animation: .easeOut(duration: 0.2))) {
            verticalDragOffset = 300
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// Helper extension to disable animations
extension View {
    func withoutAnimation(_ action: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            action()
        }
    }
}
