import SwiftUI
import AVFoundation

struct WorkoutCameraSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var nutritionStore: NutritionStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @StateObject private var viewModel = CameraViewModel()
    @State private var foodInput: String = ""
    @State private var selectedWorkout: (name: String, color: Color)? = nil
    @State private var isAnalyzing = false
    @State private var throwPosition: CGSize = .zero
    @Namespace private var animation
    
    let workouts = [
        (name: "Chest", color: Color.red, icon: "figure.strengthtraining.traditional"),
        (name: "Back", color: Color.yellow, icon: "figure.walk"),
        (name: "Legs", color: Color.blue, icon: "figure.walk"),
        (name: "Cardio", color: Color.green, icon: "heart.slash.fill")
    ]
    
    var body: some View {
        ZStack {
            // Camera Background
            if viewModel.isAuthorized && viewModel.isSessionRunning {
                if let session = viewModel.captureSession {
                    GeometryReader { geometry in
                        ZStack {
                            CameraPreviewView(session: session)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .overlay(
                                    Button(action: {
                                        viewModel.capturePhoto { image in
                                            if let image = image {
                                                // Handle captured image
                                                analyzeFoodFromImage(image)
                                            }
                                        }
                                    }) {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                            .frame(width: 70, height: 70)
                                            .background(Circle().fill(Color.white.opacity(0.25)))
                                    }
                                    .disabled(isAnalyzing)
                                    .padding(.bottom, 30),
                                    alignment: .bottom
                                )
                            
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
            }
            
            // Content Overlay
            VStack(spacing: 20) {
                // Top Navigation Bar
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()
                
                // Workout Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(workouts.indices, id: \.self) { index in
                        let workout = workouts[index]
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedWorkout = (workout.name, workout.color)
                                throwPosition = CGSize(width: 0, height: -UIScreen.main.bounds.height * 0.4)
                            }

                            // Add workout to store with appropriate muscle groups
                            let muscleGroup: MuscleGroup
                            switch workout.name {
                            case "Chest":
                                muscleGroup = .chest
                            case "Back":
                                muscleGroup = .back
                            case "Legs":
                                muscleGroup = .legs
                            case "Cardio":
                                muscleGroup = .cardio
                            default:
                                muscleGroup = .core
                            }
                            
                            workoutStore.addWorkout(
                                muscleGroups: [muscleGroup],
                                name: workout.name,
                                duration: 0,
                                exercises: [],
                                for: Date()
                            )

                            // Dismiss after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                isPresented = false
                            }
                        }) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(workout.color.opacity(0.1))
                                .frame(height: 100)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: workout.icon)
                                            .font(.system(size: 28))
                                            .foregroundColor(workout.color)
                                        Text(workout.name)
                                            .font(.title3)
                                            .foregroundColor(workout.color)
                                            .fontWeight(.semibold)
                                    }
                                )
                                .matchedGeometryEffect(id: workout.name, in: animation)
                                .offset(selectedWorkout?.name == workout.name ? throwPosition : .zero)
                                .scaleEffect(selectedWorkout?.name == workout.name ? 0.7 : 1)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Add Food Section
                VStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                        
                        Text("Add")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Food")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        TextField("A banana and a small milkshake", text: $foodInput)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(15)
                        
                        Button(action: {
                            analyzeFoodAndAnimate()
                        }) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    private func analyzeFoodAndAnimate() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isAnalyzing = true
            throwPosition = CGSize(width: 0, height: -UIScreen.main.bounds.height * 0.4)
        }
        
        // Simulate analysis time and add to meals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString = timeFormatter.string(from: Date())
            
            let meal = Meal(
                id: UUID(),
                name: foodInput,
                calories: 300, // Example values
                protein: 20,
                carbs: 40,
                fat: 10,
                time: timeString
            )
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                nutritionStore.addMeal(meal, for: Date())
            }
            
            // Dismiss sheet after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPresented = false
            }
        }
    }
    
    private func analyzeFoodFromImage(_ image: UIImage) {
        isAnalyzing = true
        
        // Resize image to reasonable dimensions
        let targetSize = CGSize(width: 600, height: 600)
        let resizedImage = resizeImage(image, targetSize: targetSize)
        
        // Convert to base64 with compression
        guard let base64String = compressAndConvertToBase64(resizedImage) else {
            isAnalyzing = false
            return
        }
        
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
                let analysis = try await ChatGPTService().analyzeFoodEntry(entry)
                
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
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let maxDimension: CGFloat = 600
        let scaledTargetSize = CGSize(
            width: min(targetSize.width, maxDimension),
            height: min(targetSize.height, maxDimension)
        )
        
        let widthRatio = scaledTargetSize.width / size.width
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
        var compression: CGFloat = 0.6
        let maxCompression: CGFloat = 0.1
        let maxFileSize = 500 * 1024
        
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxFileSize && compression > maxCompression {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let finalData = imageData else { return nil }
        return finalData.base64EncodedString()
    }
} 