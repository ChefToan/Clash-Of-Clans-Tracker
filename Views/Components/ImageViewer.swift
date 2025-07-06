// ImageViewer.swift
import SwiftUI
import Photos
import Kingfisher

struct ImageViewer: View {
    let url: URL?
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var loadedImage: UIImage?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var isLoadingImage = false
    @State private var dragOffset: CGSize = .zero
    @State private var opacity: Double = 1.0
    
    private let dismissThreshold: CGFloat = 150
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(opacity * 0.9)
                .ignoresSafeArea()
            
            if let url = url {
                KFImage(url)
                    .onSuccess { result in
                        loadedImage = result.image
                    }
                    .onFailure { error in
                        print("Failed to load image: \(error)")
                    }
                    .placeholder {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    .fade(duration: 0.3)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.width, y: offset.height + dragOffset.height)
                    .opacity(opacity)
                    .gesture(
                        // Only allow drag to dismiss when not zoomed
                        scale <= 1.0 ?
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                                // Calculate opacity based on drag distance
                                let progress = Double(abs(value.translation.height) / dismissThreshold)
                                opacity = max(0.3, 1 - progress * 0.5)
                            }
                            .onEnded { value in
                                if abs(value.translation.height) > dismissThreshold {
                                    // Dismiss
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        dragOffset.height = value.translation.height > 0 ?
                                            UIScreen.main.bounds.height : -UIScreen.main.bounds.height
                                        opacity = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isPresented = false
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.spring()) {
                                        dragOffset = .zero
                                        opacity = 1.0
                                    }
                                }
                            }
                        : nil
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                if dragOffset == .zero { // Only allow zoom when not dragging
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        scale > 1.0 ?
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                if scale <= 1 {
                                    withAnimation {
                                        offset = .zero
                                    }
                                }
                            }
                        : nil
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale > 1 {
                                scale = 1
                                offset = .zero
                            } else {
                                scale = 2
                            }
                        }
                    }
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
                        isPresented = false
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
