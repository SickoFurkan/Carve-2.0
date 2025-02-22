import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Nutrition Header View
private struct NutritionHeaderView: View {
    let nutritionStore: NutritionStore
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                // Left side - Large number with animation
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 0) {
                        AnimatedCounter(
                            value: nutritionStore.getTotalCaloriesForDate(selectedDate),
                            fontSize: 48,
                            fontWeight: .bold,
                            textColor: .primary
                        )
                        
                        Text("calories")
                            .font(.system(size: 20))
                            .foregroundColor(.primary.opacity(0.8))
                    }
                }
                
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
    }
}

// MARK: - Food Diary View
private struct FoodDiaryView: View {
    let nutritionStore: NutritionStore
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Food")
                .font(.headline)
            
            ForEach(nutritionStore.getMealsForDate(selectedDate), id: \.id) { meal in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(meal.calories) kcal • P: \(meal.protein)g • F: \(meal.fat)g • C: \(meal.carbs)g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quick add buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            nutritionStore.addMeal(meal, for: selectedDate)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 24))
                        }
                        
                        Button(action: {
                            nutritionStore.removeMeal(meal, for: selectedDate)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 24))
                        }
                    }
                }
                .padding(.vertical, 8)
                
                if meal.id != nutritionStore.getMealsForDate(selectedDate).last?.id {
                    Divider()
                }
            }
        }
    }
}

// MARK: - Models
struct Post: Identifiable {
    let id = UUID()
    let userImage: String
    let username: String
    let type: PostType
    let description: String
    let timestamp: Date
    var likes: Int
    var hasLiked: Bool
    var comments: Int
}

enum PostType {
    case food
    case workout
    case progress
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .workout: return "figure.strengthtraining"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .blue
        case .workout: return .green
        case .progress: return .orange
        }
    }
}

// MARK: - Action Card Views
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(width: 120, height: 100)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 2)
        }
    }
}

struct ProgressCard: View {
    let nutritionStore: NutritionStore
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vandaag")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("\(nutritionStore.getTotalCaloriesForDate(selectedDate))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("\(nutritionStore.getTotalProteinForDate(selectedDate))g")
                        .font(.subheadline)
                    Text("Proteïne")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onComment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.headline)
                    Text(post.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: post.type.icon)
                    .foregroundColor(post.type.color)
            }
            
            // Content
            Text(post.description)
                .font(.body)
            
            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack {
                        Image(systemName: post.hasLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.hasLiked ? .red : .gray)
                        Text("\(post.likes)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: onComment) {
                    HStack {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.gray)
                        Text("\(post.comments)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

// MARK: - Quick Capture Card
struct QuickCaptureCard: View {
    let onCameraTap: () -> Void
    let onLibraryTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and hint
            HStack {
                Text("Quick Add")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("Take a photo or choose from library")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                // Camera Button
                Button(action: onCameraTap) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                        Text("Camera")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Library Button
                Button(action: onLibraryTap) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24))
                        Text("Library")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

// MARK: - Main HomePageView
struct HomePageView: View {
    @StateObject private var viewModel = FoodEntryViewModel()
    @EnvironmentObject private var firebaseService: FirebaseService
    @EnvironmentObject private var profileManager: ProfileManager
    @ObservedObject private var nutritionStore: NutritionStore
    @Binding private var selectedDate: Date
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var scrollViewProxy: ScrollViewProxy?
    @StateObject private var cameraManager = CameraManager()
    
    // Mock data for testing
    @State private var posts: [Post] = [
        Post(userImage: "person.circle", username: "Furkan", type: .food, 
             description: "Maaltijd gelogd: 120g Kip, 200g Rijst", timestamp: Date(), 
             likes: 5, hasLiked: false, comments: 2),
        Post(userImage: "person.circle", username: "Emma", type: .workout, 
             description: "Bench Press PR: 100kg 💪", timestamp: Date().addingTimeInterval(-3600), 
             likes: 12, hasLiked: true, comments: 4),
        Post(userImage: "person.circle", username: "Lars", type: .progress, 
             description: "2kg afgevallen deze week! 🎉", timestamp: Date().addingTimeInterval(-7200), 
             likes: 8, hasLiked: false, comments: 3)
    ]
    
    public init(selectedDate: Binding<Date>, nutritionStore: NutritionStore) {
        self._selectedDate = selectedDate
        self.nutritionStore = nutritionStore
    }
    
    private func handleSelectedImage(_ image: UIImage) {
        selectedImage = image
        isAnalyzing = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            
            await MainActor.run {
                nutritionStore.addMeal(
                    Meal(
                        name: "Photo Analysis",
                        calories: 400,
                        protein: 25,
                        carbs: 45,
                        fat: 15
                    ),
                    for: selectedDate
                )
                
                isAnalyzing = false
                selectedImage = nil
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Top anchor view
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                    
                    // Nutrition Card
                    NutritionCard(nutritionStore: nutritionStore, selectedDate: selectedDate)
                        .padding(.horizontal)
                    
                    // Quick Capture Card
                    QuickCaptureCard(
                        onCameraTap: { showingCamera = true },
                        onLibraryTap: { showingImagePicker = true }
                    )
                    .padding(.horizontal)
                    .overlay {
                        if isAnalyzing {
                            ZStack {
                                Color.black.opacity(0.7)
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("Analyzing photo...")
                                        .foregroundColor(.white)
                                }
                            }
                            .cornerRadius(16)
                        }
                    }
                    
                    // Quick Workout Card
                    QuickWorkoutCard()
                        .padding(.horizontal)
                    
                    // Go to top button
                    Button(action: {
                        withAnimation(.spring()) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up")
                                .font(.caption)
                            Text("Go to Top")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                    }
                }
                .padding(.top)
            }
            .onAppear {
                scrollViewProxy = proxy
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(nutritionStore: nutritionStore)
                .environmentObject(cameraManager)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                .onChange(of: selectedImage) { oldValue, newValue in
                    if let image = newValue {
                        handleSelectedImage(image)
                        showingImagePicker = false
                    }
                }
        }
    }
}

// MARK: - Circular Calorie Progress
struct CircularCalorieProgress: View {
    let current: Double
    let target: Double
    
    private var progress: Double {
        min(current / target, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Calorie Text
            VStack(spacing: 4) {
                Text("\(Int(current))")
                    .font(.system(size: 32, weight: .bold))
                Text("/ \(Int(target))")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text("calories")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Nutrition Card
struct NutritionCard: View {
    let nutritionStore: NutritionStore
    let selectedDate: Date
    
    // Example target calories - you should get this from your nutrition store
    let targetCalories: Double = 2500
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 24) {
                // Left side - Circular Calorie Progress
                CircularCalorieProgress(
                    current: Double(nutritionStore.getTotalCaloriesForDate(selectedDate)),
                    target: targetCalories
                )
                .frame(width: 150, height: 150)
                
                // Right side - Macros
                VStack(spacing: 24) {
                    MacroIndicator(
                        label: "Protein",
                        value: Double(nutritionStore.getTotalProteinForDate(selectedDate)),
                        target: 150,
                        color: .blue
                    )
                    MacroIndicator(
                        label: "Carbs",
                        value: Double(nutritionStore.getTotalCarbsForDate(selectedDate)),
                        target: 300,
                        color: .green
                    )
                    MacroIndicator(
                        label: "Fat",
                        value: Double(nutritionStore.getTotalFatForDate(selectedDate)),
                        target: 65,
                        color: .orange
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Analyzed Items List
            if !nutritionStore.getMealsForDate(selectedDate).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Food Items")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(nutritionStore.getMealsForDate(selectedDate), id: \.id) { meal in
                                FoodItemBadge(name: meal.name)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct FoodItemBadge: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(16)
    }
}

// MARK: - Macro Indicator
struct MacroIndicator: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    
    var progress: Double {
        min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .center, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(value))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(width: geometry.size.width, height: 4)
                    
                    // Progress bar
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            
            Text("\(Int(target))g")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Workout Card
struct QuickWorkoutCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Workouts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                WorkoutButton(title: "Strength", icon: "dumbbell.fill", color: .blue)
                WorkoutButton(title: "Cardio", icon: "heart.fill", color: .red)
                WorkoutButton(title: "HIIT", icon: "flame.fill", color: .orange)
                WorkoutButton(title: "Yoga", icon: "figure.mind.and.body", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

// MARK: - Workout Button
struct WorkoutButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Handle workout selection
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
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

struct AnimatedCounter: View {
    let value: Int
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let textColor: Color
    @State private var animationValue: Int = 0
    
    init(value: Int, fontSize: CGFloat = 64, fontWeight: Font.Weight = .bold, textColor: Color = .primary) {
        self.value = value
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.textColor = textColor
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                let divisor = pow(10.0, Double(3 - index))
                let animatedDigit = (animationValue / Int(divisor)) % 10
                
                SlideDigit(
                    digit: animatedDigit,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    textColor: textColor
                )
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animationValue = newValue
            }
        }
        .onAppear {
            animationValue = value
        }
    }
}

struct SlideDigit: View {
    let digit: Int
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(-1...1, id: \.self) { offset in
                Text("\((digit + offset + 10) % 10)")
                    .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(width: fontSize * 0.6)
                    .opacity(offset == 0 ? 1 : 0)
            }
        }
        .frame(height: fontSize)
        .clipped()
        .contentShape(Rectangle())
        .transition(.slide)
    }
}

#Preview {
    HomePageView(selectedDate: .constant(Date()), nutritionStore: .shared)
        .environmentObject(FirebaseService.shared)
        .environmentObject(ProfileManager.shared)
} 
