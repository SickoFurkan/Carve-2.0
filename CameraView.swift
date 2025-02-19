import SwiftUI
import AVFoundation
import Photos

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isAuthorized = false
    @Published var error: String?
    @Published var showError = false
    @Published var isSessionRunning = false
    
    private var _captureSession: AVCaptureSession?
    private var photoOutput = AVCapturePhotoOutput()
    private var completionHandler: ((UIImage?) -> Void)?
    
    var captureSession: AVCaptureSession? {
        get { _captureSession }
    }
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCaptureSession()
                    }
                }
            }
        default:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = false
                self?.error = "Camera access is not authorized. Please enable it in Settings."
                self?.showError = true
            }
        }
    }
    
    private func setupCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            
            do {
                session.beginConfiguration()
                
                // Get video device
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                              for: .video,
                                                              position: .back) else {
                    throw NSError(domain: "CameraError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to access camera device"])
                }
                
                // Add video input
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                guard session.canAddInput(videoInput) else {
                    throw NSError(domain: "CameraError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not add video input"])
                }
                session.addInput(videoInput)
                
                // Add photo output
                guard session.canAddOutput(self.photoOutput) else {
                    throw NSError(domain: "CameraError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not add photo output"])
                }
                session.addOutput(self.photoOutput)
                
                // Configure session
                session.sessionPreset = .photo
                
                // Commit configuration
                session.commitConfiguration()
                
                self._captureSession = session
                
                // Start running the session
                session.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.showError = true
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let captureSession = _captureSession, captureSession.isRunning else {
            self.error = "Camera is not ready"
            self.showError = true
            completion(nil)
            return
        }
        
        self.completionHandler = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // AVCapturePhotoCaptureDelegate method
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = "Failed to capture photo: \(error.localizedDescription)"
                self?.showError = true
                self?.completionHandler?(nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async { [weak self] in
                self?.error = "Failed to process photo"
                self?.showError = true
                self?.completionHandler?(nil)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(image)
        }
    }
    
    func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self?.error = "Photo library access denied"
                    self?.showError = true
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { [weak self] success, error in
                DispatchQueue.main.async {
                    if !success {
                        self?.error = "Failed to save photo"
                        self?.showError = true
                    }
                }
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Start the session on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            if !session.isRunning {
                session.startRunning()
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @ObservedObject var nutritionStore: NutritionStore
    @State private var isAnalyzing = false
    @Environment(\.dismiss) private var dismiss
    private let chatGPTService = ChatGPTService()
    
    init(nutritionStore: NutritionStore) {
        self.nutritionStore = nutritionStore
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.isAuthorized && viewModel.isSessionRunning {
                if let session = viewModel.captureSession {
                    GeometryReader { geometry in
                        ZStack {
                            CameraPreviewView(session: session)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .onAppear {
                                    // Start session on a background thread
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        if !session.isRunning {
                                            session.startRunning()
                                        }
                                    }
                                }
                                .onDisappear {
                                    // Instead of stopping immediately, add a small delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        // Only stop if the view is still not visible
                                        if !viewModel.isSessionRunning {
                                            DispatchQueue.global(qos: .userInitiated).async {
                                                if session.isRunning {
                                                    session.stopRunning()
                                                }
                                            }
                                        }
                                    }
                                }
                            
                            // Camera controls
                            VStack {
                                Spacer()
                                Button(action: captureAndAnalyze) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 60, height: 60)
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 70, height: 70)
                                    }
                                }
                                .disabled(isAnalyzing)
                                .padding(.bottom, 40)
                            }
                            
                            if isAnalyzing {
                                Color.black.opacity(0.5)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    )
                            }
                        }
                    }
                }
            } else if !viewModel.isAuthorized {
                VStack(spacing: 20) {
                    Text("Camera access is required")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .foregroundColor(.blue)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onDisappear {
            // Ensure cleanup when view disappears
            if let session = viewModel.captureSession {
                DispatchQueue.global(qos: .userInitiated).async {
                    if session.isRunning {
                        session.stopRunning()
                    }
                }
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.error ?? "Unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func captureAndAnalyze() {
        isAnalyzing = true
        
        viewModel.capturePhoto { image in
            guard let image = image else {
                isAnalyzing = false
                return
            }
            
            // Resize image to reasonable dimensions
            let targetSize = CGSize(width: 600, height: 600)
            let resizedImage = resizeImage(image, targetSize: targetSize)
            
            // Convert to base64 with compression
            guard let base64String = compressAndConvertToBase64(resizedImage) else {
                isAnalyzing = false
                viewModel.error = "Failed to process photo"
                viewModel.showError = true
                return
            }
            
            print("📸 Starting analysis with image size: \(base64String.count / 1024)KB")
            
            // Create a FoodEntry and analyze
            let entry = FoodEntry(
                name: "Food from Image",
                description: "",
                amount: 100,
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                imageBase64: base64String
            )
            
            Task {
                do {
                    let analysis = try await chatGPTService.analyzeFoodEntry(entry)
                    print("✅ Analysis successful: \(analysis.details)")
                    
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    let timeString = timeFormatter.string(from: Date())
                    
                    let meal = Meal(
                        id: UUID(),
                        name: analysis.details,
                        calories: analysis.calories,
                        protein: analysis.protein,
                        carbs: analysis.carbs,
                        fat: analysis.fat,
                        time: timeString
                    )
                    
                    await MainActor.run {
                        nutritionStore.addMeal(meal, for: Date())
                        isAnalyzing = false
                    }
                } catch {
                    print("❌ Analysis failed: \(error.localizedDescription)")
                    await MainActor.run {
                        viewModel.error = String(format: "Failed to analyze: %@", error.localizedDescription)
                        viewModel.showError = true
                        isAnalyzing = false
                    }
                }
            }
        }
    }
    
    // MARK: - Image Processing Helpers
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let maxDimension: CGFloat = 600
        let scaledTargetSize = CGSize(
            width: min(targetSize.width, maxDimension),
            height: min(targetSize.height, maxDimension)
        )
        
        // Calculate aspect ratios
        let screenAspectRatio = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        let imageAspectRatio = size.width / size.height
        
        // Calculate crop rect
        var cropRect: CGRect
        if imageAspectRatio > screenAspectRatio {
            // Image is wider than screen
            let newWidth = size.height * screenAspectRatio
            let xOffset = (size.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: size.height)
        } else {
            // Image is taller than screen
            let newHeight = size.width / screenAspectRatio
            let yOffset = (size.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: size.width, height: newHeight)
        }
        
        // Crop the image
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        // Now resize the cropped image
        let widthRatio  = scaledTargetSize.width  / cropRect.width
        let heightRatio = scaledTargetSize.height / cropRect.height
        
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: cropRect.width * ratio, height: cropRect.height * ratio)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        croppedImage.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func compressAndConvertToBase64(_ image: UIImage) -> String? {
        var compression: CGFloat = 0.6
        let maxCompression: CGFloat = 0.1
        let maxFileSize = 500 * 1024
        
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxFileSize && compression > maxCompression {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let finalData = imageData else { return nil }
        
        let finalSize = Double(finalData.count) / 1024.0
        print("📸 Final image size: \(String(format: "%.2f", finalSize))KB")
        print("🔍 Compression quality: \(String(format: "%.2f", compression))")
        
        return finalData.base64EncodedString()
    }
} 