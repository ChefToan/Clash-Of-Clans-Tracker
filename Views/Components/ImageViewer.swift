// ImageViewer.swift
import SwiftUI
import Photos
import Kingfisher

struct ImageViewer: View {
    let url: URL?
    @Binding var isPresented: Bool
    @State private var loadedImage: UIImage?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var isLoadingImage = false
    @State private var dragOffset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var isDismissing = false
    
    private let dismissThreshold: CGFloat = 150
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(opacity * 0.9)
                .ignoresSafeArea()
            
            if let url = url {
                ZoomableImageView(
                    url: url,
                    loadedImage: $loadedImage,
                    dragOffset: $dragOffset,
                    opacity: $opacity,
                    dismissThreshold: dismissThreshold,
                    onDismiss: {
                        dismissWithAnimation()
                    }
                )
                .opacity(opacity)
                .offset(y: dragOffset.height)
                .contextMenu {
                    Button {
                        saveImage()
                    } label: {
                        Label("Save Image", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        copyImage()
                    } label: {
                        Label("Copy Image", systemImage: "doc.on.doc")
                    }
                    
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text("No image URL provided")
                        .foregroundColor(.white)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismissWithAnimation()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    .opacity(opacity)
                }
                Spacer()
            }
            
            // Loading overlay for save operation
            if isLoadingImage {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView("Loading image...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .alert("Save Image", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
        .gesture(
            // Only allow drag to dismiss when not zoomed and not already dismissing
            DragGesture()
                .onChanged { value in
                    if !isDismissing {
                        dragOffset = value.translation
                        let progress = Double(abs(value.translation.height) / dismissThreshold)
                        opacity = max(0.3, 1 - progress * 0.5)
                    }
                }
                .onEnded { value in
                    if !isDismissing {
                        if abs(value.translation.height) > dismissThreshold {
                            dismissWithAnimation()
                        } else {
                            // Snap back
                            withAnimation(.spring()) {
                                dragOffset = .zero
                                opacity = 1.0
                            }
                        }
                    }
                }
        )
    }
    
    private func dismissWithAnimation() {
        guard !isDismissing else { return }
        isDismissing = true
        
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset.height = dragOffset.height != 0 ?
                (dragOffset.height > 0 ? UIScreen.main.bounds.height : -UIScreen.main.bounds.height) :
                UIScreen.main.bounds.height
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
    
    private func saveImage() {
        guard let url = url else {
            saveAlertMessage = "No image URL available"
            showSaveAlert = true
            return
        }
        
        // If we already have the image loaded from Kingfisher, use it
        if let image = loadedImage {
            performSave(with: image)
        } else {
            // Otherwise, download it again
            isLoadingImage = true
            
            KingfisherManager.shared.retrieveImage(with: url) { result in
                DispatchQueue.main.async {
                    isLoadingImage = false
                    
                    switch result {
                    case .success(let imageResult):
                        performSave(with: imageResult.image)
                    case .failure(let error):
                        saveAlertMessage = "Failed to download image: \(error.localizedDescription)"
                        showSaveAlert = true
                        HapticManager.shared.errorFeedback()
                    }
                }
            }
        }
    }
    
    private func performSave(with image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            saveAlertMessage = "Image saved to Photos"
                            HapticManager.shared.successFeedback()
                        } else {
                            saveAlertMessage = "Failed to save image: \(error?.localizedDescription ?? "Unknown error")"
                            HapticManager.shared.errorFeedback()
                        }
                        showSaveAlert = true
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    saveAlertMessage = "Please allow access to Photos in Settings"
                    showSaveAlert = true
                    HapticManager.shared.errorFeedback()
                }
            case .notDetermined:
                // Request permission again
                PHPhotoLibrary.requestAuthorization { _ in
                    saveImage()
                }
            @unknown default:
                break
            }
        }
    }
    
    private func copyImage() {
        // If we already have the image loaded, use it
        if let image = loadedImage {
            UIPasteboard.general.image = image
            saveAlertMessage = "Image copied to clipboard"
            showSaveAlert = true
            HapticManager.shared.successFeedback()
        } else if let url = url {
            // Otherwise, download it
            isLoadingImage = true
            
            KingfisherManager.shared.retrieveImage(with: url) { result in
                DispatchQueue.main.async {
                    isLoadingImage = false
                    
                    switch result {
                    case .success(let imageResult):
                        UIPasteboard.general.image = imageResult.image
                        saveAlertMessage = "Image copied to clipboard"
                        showSaveAlert = true
                        HapticManager.shared.successFeedback()
                    case .failure:
                        saveAlertMessage = "Failed to copy image"
                        showSaveAlert = true
                        HapticManager.shared.errorFeedback()
                    }
                }
            }
        } else {
            saveAlertMessage = "No image available"
            showSaveAlert = true
            HapticManager.shared.errorFeedback()
        }
    }
}

// MARK: - ZoomableImageView using UIScrollView
struct ZoomableImageView: UIViewRepresentable {
    let url: URL
    @Binding var loadedImage: UIImage?
    @Binding var dragOffset: CGSize
    @Binding var opacity: Double
    let dismissThreshold: CGFloat
    let onDismiss: () -> Void
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let imageView = UIImageView()
        
        // Configure scroll view
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // Configure image view
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .clear
        
        // Add image view to scroll view
        scrollView.addSubview(imageView)
        
        // Store references
        context.coordinator.scrollView = scrollView
        context.coordinator.imageView = imageView
        
        // Load image
        context.coordinator.loadImage()
        
        // Add double tap gesture
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        // Add single tap gesture for dismiss when not zoomed
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableImageView
        var scrollView: UIScrollView?
        var imageView: UIImageView?
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func loadImage() {
            guard let imageView = imageView else { return }
            
            KingfisherManager.shared.retrieveImage(with: parent.url) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageResult):
                        let image = imageResult.image
                        imageView.image = image
                        self?.parent.loadedImage = image
                        self?.updateImageViewFrame()
                    case .failure(let error):
                        print("Failed to load image: \(error)")
                    }
                }
            }
        }
        
        func updateImageViewFrame() {
            guard let scrollView = scrollView,
                  let imageView = imageView,
                  let image = imageView.image else { return }
            
            let scrollViewSize = scrollView.bounds.size
            let imageSize = image.size
            
            // Calculate the size to fit the image in scroll view while maintaining aspect ratio
            let widthRatio = scrollViewSize.width / imageSize.width
            let heightRatio = scrollViewSize.height / imageSize.height
            let ratio = min(widthRatio, heightRatio)
            
            let scaledImageSize = CGSize(
                width: imageSize.width * ratio,
                height: imageSize.height * ratio
            )
            
            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: scaledImageSize.width,
                height: scaledImageSize.height
            )
            
            scrollView.contentSize = scaledImageSize
            centerImageView()
        }
        
        func centerImageView() {
            guard let scrollView = scrollView,
                  let imageView = imageView else { return }
            
            let scrollViewSize = scrollView.bounds.size
            let imageViewSize = imageView.frame.size
            
            let horizontalPadding = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
            let verticalPadding = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
            
            scrollView.contentInset = UIEdgeInsets(
                top: verticalPadding,
                left: horizontalPadding,
                bottom: verticalPadding,
                right: horizontalPadding
            )
        }
        
        // MARK: - UIScrollViewDelegate
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImageView()
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            // Add haptic feedback when zoom ends
            if scale > 1.0 {
                HapticManager.shared.lightImpactFeedback()
            }
        }
        
        // MARK: - Gesture Handlers
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            
            HapticManager.shared.lightImpactFeedback()
            
            if scrollView.zoomScale > 1.0 {
                // Zoom out
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                // Zoom in to the tapped point
                let location = gesture.location(in: imageView)
                let zoomScale: CGFloat = 2.0
                let zoomRect = zoomRectForScale(zoomScale, center: location)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
        
        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            
            // Only dismiss on single tap if not zoomed
            if scrollView.zoomScale <= 1.0 {
                parent.onDismiss()
            }
        }
        
        private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
            guard let scrollView = scrollView else { return .zero }
            
            let width = scrollView.frame.size.width / scale
            let height = scrollView.frame.size.height / scale
            let x = center.x - (width / 2.0)
            let y = center.y - (height / 2.0)
            
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
}
