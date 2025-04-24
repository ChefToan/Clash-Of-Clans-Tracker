// ZoomableImageView.swift - Updated to handle orientation changes
import SwiftUI
import UIKit

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onSwipeDown: () -> Void
    
    func makeUIView(context: Context) -> UIScrollView {
        // Create scroll view with proper configuration
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear
        scrollView.decelerationRate = .normal
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // Create image view with proper configuration
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        context.coordinator.imageView = imageView
        
        // Add image view to scroll view
        scrollView.addSubview(imageView)
        
        // Setup gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        scrollView.addGestureRecognizer(tapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        scrollView.addGestureRecognizer(longPressGesture)
        
        // Add swipe down gesture
        let swipeGesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipeDown))
        swipeGesture.direction = .down
        scrollView.addGestureRecognizer(swipeGesture)
        
        // Make sure single tap doesn't trigger with double tap
        tapGesture.require(toFail: doubleTapGesture)
        
        // Add orientation change observer
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = context.coordinator.imageView,
              scrollView.bounds.size.width > 0,
              scrollView.bounds.size.height > 0 else { return }
        
        // Check if bounds changed significantly (e.g., orientation change or initial layout)
        let currentSize = scrollView.bounds.size
        let previousSize = context.coordinator.previousScrollViewSize
        
        let sizeChanged = abs(currentSize.width - previousSize.width) > 1 ||
                          abs(currentSize.height - previousSize.height) > 1
        
        if sizeChanged || context.coordinator.isInitialLayout {
            context.coordinator.previousScrollViewSize = currentSize
            context.coordinator.updateImageLayout(scrollView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    static func dismantleUIView(_ uiView: UIScrollView, coordinator: Coordinator) {
        // Remove orientation change observer
        NotificationCenter.default.removeObserver(coordinator)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableImageView
        var imageView: UIImageView?
        var isInitialLayout = true
        var previousScrollViewSize: CGSize = .zero
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerScrollViewContents(scrollView)
        }
        
        @objc func orientationChanged(_ notification: Notification) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let scrollView = self.imageView?.superview as? UIScrollView else { return }
                
                // Add a slight delay to ensure bounds are updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateImageLayout(scrollView)
                }
            }
        }
        
        func updateImageLayout(_ scrollView: UIScrollView) {
            guard let imageView = imageView,
                  scrollView.bounds.size.width > 0,
                  scrollView.bounds.size.height > 0 else { return }
            
            let scrollViewSize = scrollView.bounds.size
            let imageSize = parent.image.size
            
            // Calculate minimum scale to fit the image properly
            let widthScale = scrollViewSize.width / imageSize.width
            let heightScale = scrollViewSize.height / imageSize.height
            let minScale = min(widthScale, heightScale)
            
            // Update zoom scales based on new dimensions
            scrollView.minimumZoomScale = minScale
            scrollView.maximumZoomScale = minScale * 3.0
            
            // If initial layout or orientation change reset to proper fit
            if isInitialLayout || scrollView.zoomScale < minScale {
                scrollView.zoomScale = minScale
            } else {
                // Maintain zoom level but clamp within valid range
                scrollView.zoomScale = max(minScale, min(scrollView.zoomScale, minScale * 3.0))
            }
            
            // Resize image view based on current zoom
            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: imageSize.width * scrollView.zoomScale,
                height: imageSize.height * scrollView.zoomScale
            )
            
            // Center content
            centerScrollViewContents(scrollView)
            
            // Mark initial layout as complete if needed
            if isInitialLayout {
                isInitialLayout = false
            }
        }
        
        func centerScrollViewContents(_ scrollView: UIScrollView) {
            guard let imageView = imageView else { return }
            
            let scrollViewSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize
            
            let horizontalInset = max(0, (scrollViewSize.width - contentSize.width) / 2)
            let verticalInset = max(0, (scrollViewSize.height - contentSize.height) / 2)
            
            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }
        
        @objc func handleTap() {
            // Only tap to dismiss if not zoomed in
            if let scrollView = imageView?.superview as? UIScrollView,
               abs(scrollView.zoomScale - scrollView.minimumZoomScale) < 0.01 {
                parent.onTap()
            }
        }
        
        @objc func handleDoubleTap(sender: UITapGestureRecognizer) {
            guard let scrollView = imageView?.superview as? UIScrollView,
                  let imageView = imageView else { return }
            
            if scrollView.zoomScale > scrollView.minimumZoomScale + 0.01 {
                // Zoom out to minimum
                UIView.animate(withDuration: 0.3) {
                    scrollView.zoomScale = scrollView.minimumZoomScale
                }
            } else {
                // Get tap point in image coordinates
                let point = sender.location(in: imageView)
                
                // Calculate zoom rect (zooming to ~60% of max zoom provides better UX)
                let targetZoom = scrollView.maximumZoomScale * 0.6
                let width = scrollView.bounds.width / targetZoom
                let height = scrollView.bounds.height / targetZoom
                let x = max(0, point.x - width/2)
                let y = max(0, point.y - height/2)
                
                let zoomRect = CGRect(x: x, y: y, width: width, height: height)
                
                // Zoom to rect with animation
                UIView.animate(withDuration: 0.3) {
                    scrollView.zoom(to: zoomRect, animated: false)
                }
            }
        }
        
        @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
            if sender.state == .began {
                parent.onLongPress()
            }
        }
        
        @objc func handleSwipeDown(sender: UISwipeGestureRecognizer) {
            // Only dismiss if not zoomed in
            if let scrollView = imageView?.superview as? UIScrollView,
               abs(scrollView.zoomScale - scrollView.minimumZoomScale) < 0.01 {
                parent.onSwipeDown()
            }
        }
    }
}
