import SwiftUI
import PhotosUI

public struct HomePageView: View {
    @StateObject private var viewModel = FoodEntryViewModel()
    @EnvironmentObject private var firebaseService: FirebaseService
    @EnvironmentObject private var profileManager: ProfileManager
    @Binding private var selectedDate: Date
    @State private var selectedImage: PhotosPickerItem?
    @State private var isAnalyzing = false
    private var nutritionStore: NutritionStore
    private let chatGPTService = ChatGPTService()
    
    public init(selectedDate: Binding<Date>, nutritionStore: NutritionStore) {
        self._selectedDate = selectedDate
        self.nutritionStore = nutritionStore
    }
    
    public var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Photo Library Card
                    CardView {
                        PhotosPicker(selection: $selectedImage,
                                   matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 32))
                                Text("Choose from Library")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                        }
                        .overlay {
                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .cardStyle()
                    
                    // Food Entries List
                    FoodEntriesList(
                        viewModel: viewModel,
                        nutritionStore: nutritionStore,
                        selectedDate: $selectedDate
                    )
                    .cardStyle()
                }
                .padding(.vertical)
            }
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
                        selectedImage = nil
                    }
                } catch {
                    print("❌ Analysis failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isAnalyzing = false
                        selectedImage = nil
                    }
                }
                
            } catch {
                print("❌ Error processing image: \(error.localizedDescription)")
                await MainActor.run {
                    isAnalyzing = false
                    selectedImage = nil
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

#Preview {
    HomePageView(
        selectedDate: .constant(Date()),
        nutritionStore: NutritionStore()
    )
} 
