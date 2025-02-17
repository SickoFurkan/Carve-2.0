import SwiftUI
import UIKit

@MainActor
public class FoodEntryViewModel: ObservableObject {
    @Published public var foodName: String = ""
    @Published public var foodAmount: String = ""
    @Published public var isAnalyzing: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var analyzedResult: String? = nil
    @Published public var showErrorAlert: Bool = false
    @Published public var currentAnalysis: FoodAnalysis?
    @Published public var capturedImage: UIImage?
    @Published public var isShowingImagePicker: Bool = false
    @Published public var analyzedFoodName: String = ""
    @Published public var foodEntries: [FoodEntry] = []
    
    private let chatGPTService: ChatGPTService
    private let firebaseService = FirebaseService.shared
    private var selectedDate: Date
    
    public init(selectedDate: Date = Date()) {
        self.chatGPTService = ChatGPTService()
        self.selectedDate = selectedDate
        Task {
            await loadFoodEntries()
        }
    }
    
    public func updateSelectedDate(_ date: Date) {
        selectedDate = date
        Task {
            await loadFoodEntries()
        }
    }
    
    private func compressImage(_ image: UIImage) -> String? {
        // Eerst schalen we de afbeelding naar een kleinere grootte
        let maxSize: CGFloat = 800 // Maximum breedte of hoogte
        let scale = min(maxSize/image.size.width, maxSize/image.size.height, 1)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Dan comprimeren we de afbeelding met een lage kwaliteit
        return scaledImage?.jpegData(compressionQuality: 0.1)?.base64EncodedString()
    }
    
    public func analyzeFoodEntry() async -> FoodAnalysis? {
        isAnalyzing = true
        errorMessage = nil
        
        do {
            let entry: FoodEntry
            if let image = capturedImage {
                // Create a food entry with the compressed image
                guard let compressedImageBase64 = compressImage(image) else {
                    errorMessage = "Kon de afbeelding niet verwerken"
                    isAnalyzing = false
                    return nil
                }
                
                entry = FoodEntry(
                    name: foodName.isEmpty ? "Foto analyse" : foodName,
                    description: "",  // We'll update this with the analysis result
                    amount: Int(foodAmount) ?? 100,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0,
                    imageBase64: compressedImageBase64
                )
            } else if !foodName.isEmpty {
                // Create a food entry without image
                guard let amount = Int(foodAmount), amount > 0 else {
                    errorMessage = "Voer een geldige hoeveelheid in"
                    isAnalyzing = false
                    return nil
                }
                
                entry = FoodEntry(
                    name: foodName,
                    description: "",  // We'll update this with the analysis result
                    amount: amount,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0
                )
            } else {
                errorMessage = "Voer een naam in of selecteer een foto"
                isAnalyzing = false
                return nil
            }
            
            print("🔄 Starting analysis for entry: \(entry.name)")
            let analysis = try await chatGPTService.analyzeFoodEntry(entry)
            print("✅ Analysis completed: \(analysis)")
            currentAnalysis = analysis
            
            // Create a new FoodEntry with the analyzed data
            let analyzedEntry = FoodEntry(
                name: entry.name,
                description: analysis.details,  // Make sure we're using the description from the analysis
                amount: entry.amount,
                calories: analysis.calories,
                protein: analysis.protein,
                carbs: analysis.carbs,
                fat: analysis.fat,
                imageBase64: entry.imageBase64
            )
            
            print("📝 Saving analyzed entry - Name: \(analyzedEntry.name), Description: \(analyzedEntry.description)")
            
            // Save to Firebase and update user profile
            try await saveFoodEntry(analyzedEntry)
            await loadFoodEntries()
            
            isAnalyzing = false
            return analysis
        } catch {
            print("❌ Analysis error: \(error)")
            errorMessage = error.localizedDescription
            isAnalyzing = false
            return nil
        }
    }
    
    private func saveFoodEntry(_ entry: FoodEntry) async throws {
        print("💾 Saving food entry:")
        print("   - Name: \(entry.name)")
        print("   - Description: \(entry.description)")
        print("   - Calories: \(entry.calories)")
        
        // First save to Firebase
        try await firebaseService.saveFoodEntry(entry)
        print("✅ Entry saved to Firebase")
        
        // Then update the user's profile
        if var profile = try await firebaseService.getUserProfile() {
            profile.addFoodEntry(entry, for: selectedDate)
            try await firebaseService.saveUserProfile(profile)
            print("✅ Profile updated with new entry")
        }
        
        // Load entries again to verify the save
        await loadFoodEntries()
        print("📝 Current entries after save:")
        for (index, entry) in foodEntries.enumerated() {
            print("   \(index + 1). \(entry.name) - \(entry.description)")
        }
    }
    
    private func loadFoodEntries() async {
        do {
            foodEntries = try await firebaseService.getFoodEntries(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func setImage(_ image: UIImage) {
        self.capturedImage = image
        self.errorMessage = nil
        self.analyzedFoodName = ""
        print("📸 Image set for analysis")
    }
    
    public func clearFields() {
        foodName = ""
        foodAmount = ""
        currentAnalysis = nil
        errorMessage = nil
        capturedImage = nil
        analyzedFoodName = ""
        print("🧹 Fields cleared")
    }
    
    public func deleteFoodEntry(_ entry: FoodEntry) async {
        do {
            // Delete from Firebase
            try await firebaseService.deleteFoodEntry(documentId: entry.id)
            
            // Refresh the list
            await loadFoodEntries()
            
            print("✅ Food entry deleted and list refreshed")
        } catch {
            errorMessage = "Could not delete food entry: \(error.localizedDescription)"
            showErrorAlert = true
            print("❌ Error deleting food entry: \(error)")
        }
    }
} 