// TrophyProgressionView.swift
import SwiftUI
import Photos

struct TrophyProgressionView: View {
    let player: Player
    private let apiService = APIService()
    @State private var chartURL: URL? = nil
    @State private var cachedImage: UIImage? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showFullScreenImage = false
    @State private var showSaveSuccess = false
    
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
                // Fixed height container to maintain consistent size
                Rectangle()
                    .fill(Constants.bgCard)
                    .frame(height: 220)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let chartImage = cachedImage {
                    // Use cached image directly
                    Image(uiImage: chartImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showFullScreenImage = true
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                saveImageToPhotoLibrary(chartImage)
                            }) {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }
                        }
                } else if let url = chartURL {
                    // Chart image display with caching
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
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            showFullScreenImage = true
                                        }
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            if let uiImage = phase.image?.asUIImage() {
                                                self.cachedImage = uiImage
                                                saveImageToPhotoLibrary(uiImage)
                                            }
                                        }) {
                                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                                        }
                                    }
                                    .onAppear {
                                        // Cache the UIImage when it loads successfully
                                        if let uiImage = phase.image?.asUIImage() {
                                            self.cachedImage = uiImage
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
                            @unknown default:
                                Text("Unknown error")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
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
            if let image = cachedImage {
                // Use the cached image directly
                EnhancedImageViewer(
                    cachedImage: image,
                    isPresented: $showFullScreenImage,
                    onSaveImage: { saveImageToPhotoLibrary(image) }
                )
                .edgesIgnoringSafeArea(.all)
            } else if let url = chartURL {
                // Fallback to URL if cached image not available
                EnhancedImageViewer(
                    imageURL: url,
                    isPresented: $showFullScreenImage,
                    onSaveImage: {
                        if let image = cachedImage {
                            saveImageToPhotoLibrary(image)
                        }
                    }
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
        .alert("Image Saved", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The chart image has been saved to your photo library.")
        }
    }
    
    private func loadChart() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.async {
            if let url = apiService.getPlayerChartImageURL(tag: player.tag) {
                self.chartURL = url
                
                // Prefetch and cache the image
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.cachedImage = image
                            self.isLoading = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            // We'll still try with AsyncImage as fallback
                            self.isLoading = false
                        }
                    }
                }.resume()
            } else {
                self.errorMessage = "Invalid player tag format"
                self.isLoading = false
            }
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access denied")
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // Show success alert on the main thread
            DispatchQueue.main.async {
                showSaveSuccess = true
            }
        }
    }
}
