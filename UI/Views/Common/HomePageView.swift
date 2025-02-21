import SwiftUI
import PhotosUI
import AVFoundation

public struct HomePageView: View {
    @StateObject private var viewModel = FoodEntryViewModel()
    @EnvironmentObject private var firebaseService: FirebaseService
    @EnvironmentObject private var profileManager: ProfileManager
    @Binding private var selectedDate: Date
    @State private var showingFullCamera = false
    @State private var isHealthy = true
    @State private var showingWorkoutSelector = false
    @State private var selectedCameraImage: UIImage?
    @State private var isAnalyzing = false
    private var nutritionStore: NutritionStore
    private let chatGPTService = ChatGPTService()
    
    public init(selectedDate: Binding<Date>, nutritionStore: NutritionStore) {
        self._selectedDate = selectedDate
        self.nutritionStore = nutritionStore
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Camera Section
                QuickCameraSection(
                    isHealthy: $isHealthy,
                    selectedImage: $selectedCameraImage,
                    isAnalyzing: $isAnalyzing,
                    nutritionStore: nutritionStore
                )
                
                // Quick Workout Section
                QuickWorkoutSection(
                    showingWorkoutSelector: $showingWorkoutSelector,
                    selectedDate: $selectedDate
                )
                
                // Friends Activity Section
                FriendsActivitySection()
            }
            .padding()
        }
        .sheet(isPresented: $showingWorkoutSelector) {
            WorkoutSelectorView(selectedDate: $selectedDate)
        }
        .refreshable {
            try? await profileManager.refreshProfile()
        }
    }
    
    private func handleSelectedImage(_ item: PhotosPickerItem) {
        isAnalyzing = true
        
        Task {
            do {
                // Load image data
                guard let imageData = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"])
                }
                
                guard let originalImage = UIImage(data: imageData) else {
                    throw NSError(domain: "ImageError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
                }
                
                // Resize image to reasonable dimensions
                let targetSize = CGSize(width: 600, height: 600)  // Reduced from 800x800
                let resizedImage = resizeImage(originalImage, targetSize: targetSize)
                
                // Convert to base64 with compression
                guard let base64String = compressAndConvertToBase64(resizedImage) else {
                    throw NSError(domain: "ImageError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to compress and encode image"])
                }
                
                print("📸 Starting analysis with image size: \(base64String.count / 1024)KB")
                
                // Create and analyze food entry
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
                        selectedCameraImage = nil
                    }
                } catch {
                    print("❌ Analysis failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isAnalyzing = false
                        selectedCameraImage = nil
                    }
                }
                
            } catch {
                print("❌ Error processing image: \(error.localizedDescription)")
                await MainActor.run {
                    isAnalyzing = false
                    selectedCameraImage = nil
                }
            }
        }
    }
    
    // MARK: - Image Processing Helpers
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        // Smaller target size
        let maxDimension: CGFloat = 600 // Reduced from 800
        let scaledTargetSize = CGSize(
            width: min(targetSize.width, maxDimension),
            height: min(targetSize.height, maxDimension)
        )
        
        let widthRatio  = scaledTargetSize.width  / size.width
        let heightRatio = scaledTargetSize.height / size.height
        
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func compressAndConvertToBase64(_ image: UIImage) -> String? {
        var compression: CGFloat = 0.6  // Start with lower quality
        let maxCompression: CGFloat = 0.1
        let maxFileSize = 500 * 1024  // Reduced to 500 KB
        
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxFileSize && compression > maxCompression {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let finalData = imageData else { return nil }
        
        // Print the final size for debugging
        let finalSize = Double(finalData.count) / 1024.0
        print("📸 Final image size: \(String(format: "%.2f", finalSize))KB")
        print("🔍 Compression quality: \(String(format: "%.2f", compression))")
        
        return finalData.base64EncodedString()
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle() -> some View {
        self
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct QuickCameraSection: View {
    @Binding var isHealthy: Bool
    @Binding var selectedImage: UIImage?
    @Binding var isAnalyzing: Bool
    @ObservedObject var nutritionStore: NutritionStore
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Food Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            ZStack {
                // Camera Preview or Selected Image
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            isAnalyzing ?
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.3))
                            : nil
                        )
                } else if cameraManager.isCameraAuthorized {
                    CameraPreview(cameraManager: cameraManager)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.slash.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Camera access required")
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // Camera Controls
                HStack(spacing: 20) {
                    // Healthy/Unhealthy Toggle
                    Button(action: { isHealthy.toggle() }) {
                        Image(systemName: isHealthy ? "leaf.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isHealthy ? .green : .orange)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    
                    // Capture Button
                    Button(action: {
                        capturePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 4)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(!cameraManager.isCameraAuthorized)
                    
                    // Switch Camera
                    Button(action: {
                        cameraManager.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(!cameraManager.isCameraAuthorized)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    private func capturePhoto() {
        cameraManager.capturePhoto { image in
            guard let image = image else { return }
            selectedImage = image
            isAnalyzing = true
            
            // Simulate API call delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // Add sample food item
                nutritionStore.addFoodItem(
                    FoodItem(
                        name: isHealthy ? "Healthy Meal" : "Unhealthy Meal",
                        calories: isHealthy ? 400 : 800,
                        protein: isHealthy ? 25 : 15,
                        carbs: isHealthy ? 45 : 80,
                        fat: isHealthy ? 15 : 35,
                        isHealthy: isHealthy
                    )
                )
                
                isAnalyzing = false
                selectedImage = nil // Reset for next capture
            }
        }
    }
}

struct QuickWorkoutSection: View {
    @Binding var showingWorkoutSelector: Bool
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Workout")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: { showingWorkoutSelector = true }) {
                HStack {
                    Image(systemName: "figure.strengthtraining")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Add Workout")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct FriendsActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friends Activity")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(1...5, id: \.self) { _ in
                        FriendActivityCard()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct FriendActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Profile Picture
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
            
            // Name
            Text("Friend Name")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Status
            Text("Completed workout")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Time
            Text("2h ago")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

#Preview {
    HomePageView(
        selectedDate: .constant(Date()),
        nutritionStore: NutritionStore()
    )
} 
