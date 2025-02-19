import SwiftUI
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isEditing = false
    
    // Temporary state variables for editing
    @Published var tempUsername: String = ""
    @Published var tempFullName: String = ""
    @Published var tempBirthDate: Date = Date()
    @Published var tempGender: UserGender = .preferNotToSay
    @Published var tempHeight: String = ""
    @Published var tempWeight: String = ""
    @Published var tempDailyCalorieGoal: String = ""
    @Published var tempDailyProteinGoal: String = ""
    @Published var tempDailyCarbsGoal: String = ""
    @Published var tempDailyFatGoal: String = ""
    
    private let firebaseService: FirebaseService
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
    }
    
    // Function to initialize temporary values
    func initializeTempValues(from profile: UserProfile) {
        tempUsername = profile.username
        tempFullName = profile.fullName
        tempBirthDate = profile.birthDate
        tempGender = profile.gender
        tempHeight = String(format: "%.0f", profile.height)
        tempWeight = String(format: "%.0f", profile.weight)
        tempDailyCalorieGoal = String(format: "%.0f", profile.dailyCalorieGoal)
        tempDailyProteinGoal = String(format: "%.0f", profile.dailyProteinGoal)
        tempDailyCarbsGoal = String(format: "%.0f", profile.dailyCarbsGoal)
        tempDailyFatGoal = String(format: "%.0f", profile.dailyFatGoal)
    }
    
    func startEditing(profile: UserProfile) {
        initializeTempValues(from: profile)
        isEditing = true
    }
    
    func createUpdatedProfile(from currentProfile: UserProfile) -> UserProfile {
        UserProfile(
            id: currentProfile.id,
            name: currentProfile.name,
            email: currentProfile.email,
            username: tempUsername,
            createdAt: currentProfile.createdAt,
            preferences: currentProfile.preferences,
            fullName: tempFullName,
            height: Double(tempHeight) ?? currentProfile.height,
            weight: Double(tempWeight) ?? currentProfile.weight,
            dailyCalorieGoal: Int(tempDailyCalorieGoal) ?? currentProfile.dailyCalorieGoal,
            dailyProteinGoal: Int(tempDailyProteinGoal) ?? currentProfile.dailyProteinGoal,
            dailyCarbsGoal: Int(tempDailyCarbsGoal) ?? currentProfile.dailyCarbsGoal,
            dailyFatGoal: Int(tempDailyFatGoal) ?? currentProfile.dailyFatGoal,
            gender: tempGender,
            birthDate: tempBirthDate,
            foodEntries: currentProfile.foodEntries
        )
    }
    
    func saveCurrentChanges() async {
        guard let currentProfile = userProfile else { return }
        let updatedProfile = createUpdatedProfile(from: currentProfile)
        await saveProfile(updatedProfile)
    }
    
    func loadUserProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let profile = try await firebaseService.getUserProfile() else {
                errorMessage = "Geen profielgegevens gevonden"
                isLoading = false
                return
            }
            userProfile = profile
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func saveProfile(_ updatedProfile: UserProfile) async {
        isLoading = true
        
        do {
            try await firebaseService.saveUserProfile(updatedProfile)
            userProfile = updatedProfile
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func calculateBMI() -> Double {
        let height = Double(tempHeight) ?? 0
        let weight = Double(tempWeight) ?? 0
        guard height > 0 else { return 0 }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    func calculateRecommendedGoals() {
        guard let weight = Double(tempWeight) else { return }
        
        // Basic calculations based on weight
        tempDailyProteinGoal = "\(Int(weight * 2))"  // 2g per kg bodyweight
        tempDailyCarbsGoal = "\(Int(weight * 3))"    // 3g per kg bodyweight
        tempDailyFatGoal = "\(Int(weight * 1))"      // 1g per kg bodyweight
        
        // Calculate BMR using weight, height, age, and gender
        let height = Double(tempHeight) ?? 170
        let age = Calendar.current.dateComponents([.year], from: tempBirthDate, to: Date()).year ?? 30
        
        var bmr: Double
        if tempGender == .male {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        // Multiply BMR by activity factor (using moderate activity = 1.55)
        let tdee = bmr * 1.55
        
        // Round to nearest 50
        let roundedCalories = Int(round(tdee / 50) * 50)
        tempDailyCalorieGoal = "\(roundedCalories)"
    }
} 