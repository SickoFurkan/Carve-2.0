import SwiftUI
import PhotosUI

struct CameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @ObservedObject var nutritionStore: NutritionStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var isAnalyzing = false
    @State private var analyzedFood: AnalyzedFood?
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if cameraManager.isCameraAuthorized {
                            CameraPreview(cameraManager: cameraManager)
                                .edgesIgnoringSafeArea(.all)
                        } else {
                            VStack {
                                Image(systemName: "camera.slash.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                Text("Camera access is required")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                    }
                    
                    // Camera controls
                    HStack(spacing: 60) {
                        Button(action: {
                            isShowingImagePicker = true
                            sourceType = .photoLibrary
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            cameraManager.capturePhoto { image in
                                if let image = image {
                                    selectedImage = image
                                    analyzeImage(image)
                                }
                            }
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                        .padding(6)
                                )
                        }
                        .disabled(!cameraManager.isCameraAuthorized)
                        
                        Button(action: {
                            cameraManager.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 30)
                }
                
                // Analysis overlay
                if isAnalyzing {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(2)
                                    .tint(.white)
                                Text("Analyzing your food...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white),
                trailing: Group {
                    if selectedImage != nil {
                        Button("Retake") {
                            selectedImage = nil
                            analyzedFood = nil
                        }
                        .foregroundColor(.white)
                    }
                }
            )
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    .onChange(of: selectedImage) { oldValue, newValue in
                        if let image = newValue {
                            analyzeImage(image)
                        }
                    }
            }
            .sheet(isPresented: $showingResults) {
                if let food = analyzedFood {
                    AnalysisResultView(food: food, nutritionStore: nutritionStore, dismiss: dismiss)
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        Task {
            do {
                let result = try await FoodAnalysisService.shared.analyzeFood(image: image)
                await MainActor.run {
                    analyzedFood = result
                    isAnalyzing = false
                    showingResults = true
                }
            } catch {
                print("Analysis error: \(error)")
                await MainActor.run {
                    isAnalyzing = false
                    // Show error alert
                }
            }
        }
    }
}

struct AnalysisResultView: View {
    let food: AnalyzedFood
    let nutritionStore: NutritionStore
    let dismiss: DismissAction
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Food name and stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text(food.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(food.calories) calories")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    // Macros
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Macronutrients")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            MacroStat(label: "Protein", value: food.protein, unit: "g")
                            MacroStat(label: "Carbs", value: food.carbs, unit: "g")
                            MacroStat(label: "Fat", value: food.fat, unit: "g")
                        }
                    }
                    
                    // Identified items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Identified Items")
                            .font(.headline)
                        
                        ForEach(food.items, id: \.self) { item in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                                Text(item)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveToNutritionStore()
                    dismiss()
                }
            )
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveToNutritionStore() {
        let meal = Meal(
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat
        )
        nutritionStore.addMeal(meal, for: Date())
    }
}

struct MacroStat: View {
    let label: String
    let value: Int
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
} 