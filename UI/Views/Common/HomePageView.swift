import SwiftUI
import PhotosUI
import AVFoundation

public struct HomePageView: View {
    @StateObject private var viewModel = FoodEntryViewModel()
    @StateObject private var cameraManager = CameraManager()
    @EnvironmentObject private var firebaseService: FirebaseService
    @EnvironmentObject private var profileManager: ProfileManager
    @ObservedObject private var nutritionStore: NutritionStore
    @Binding private var selectedDate: Date
    @State private var showingFullCamera = false
    @State private var showingWorkoutSelector = false
    private let chatGPTService = ChatGPTService()
    
    public init(selectedDate: Binding<Date>, nutritionStore: NutritionStore) {
        self._selectedDate = selectedDate
        self.nutritionStore = nutritionStore
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Nutrition Card
                VStack(spacing: 24) {
                    // Header with total calories
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            // Left side - Large number
                            Text("\(nutritionStore.getTotalCaloriesForDate(selectedDate))")
                                .font(.system(size: 64, weight: .bold))
                                .foregroundColor(.primary)
                            + Text(" kcal")
                                .font(.system(size: 24))
                                .foregroundColor(.primary.opacity(0.8))
                            
                            Spacer()
                            
                            // Right side - Macros with progress bars
                            VStack(alignment: .leading, spacing: 12) {
                                MacroProgressBar(
                                    label: "Protein",
                                    value: nutritionStore.getTotalProteinForDate(selectedDate),
                                    target: 292,
                                    color: .blue
                                )
                                MacroProgressBar(
                                    label: "Fat",
                                    value: nutritionStore.getTotalFatForDate(selectedDate),
                                    target: 404,
                                    color: .blue
                                )
                                MacroProgressBar(
                                    label: "Carbs",
                                    value: nutritionStore.getTotalCarbsForDate(selectedDate),
                                    target: 382,
                                    color: .blue
                                )
                            }
                            .frame(width: 120)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            // Progress bar
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * 0.7, height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(24)
                .cornerRadius(20)
                
                // Quick Camera Section
                QuickCameraSection(
                    nutritionStore: nutritionStore,
                    cameraManager: cameraManager,
                    selectedDate: selectedDate
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
}

struct MacroStatCard: View {
    let label: String
    let current: Int
    let target: Int
    let color: Color
    
    private var progress: CGFloat {
        CGFloat(current) / CGFloat(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(color.opacity(0.8))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            Text("\(current) / \(target)g")
                .font(.system(size: 14))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickCameraSection: View {
    @ObservedObject var nutritionStore: NutritionStore
    @ObservedObject var cameraManager: CameraManager
    let selectedDate: Date
    
    @State private var isHealthy = true
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    
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
            
            Task {
                // Simulate API call delay
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // 2 seconds
                
                await MainActor.run {
                    // Add meal using the correct model
                    nutritionStore.addMeal(
                        Meal(
                            name: isHealthy ? "Healthy Meal" : "Unhealthy Meal",
                            calories: isHealthy ? 400 : 800,
                            protein: isHealthy ? 25 : 15,
                            carbs: isHealthy ? 45 : 80,
                            fat: isHealthy ? 15 : 35
                        ),
                        for: selectedDate
                    )
                    
                    isAnalyzing = false
                    selectedImage = nil // Reset for next capture
                }
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

struct MacroStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.primary.opacity(0.8))
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let value: Int
    let target: Int
    let color: Color
    
    private var progress: CGFloat {
        CGFloat(value) / CGFloat(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            
            Text("\(value)/\(target)g")
                .font(.system(size: 12))
                .foregroundColor(.primary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress bar
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    HomePageView(
        selectedDate: .constant(Date()),
        nutritionStore: NutritionStore()
    )
} 
