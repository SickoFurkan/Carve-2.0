import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import GoogleSignInSwift
import Firebase

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var username = ""
    @Published var fullName = ""
    @Published var birthDate = Date()
    @Published var gender: UserGender = .preferNotToSay
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var activityLevel: String?
    
    // Nutrition Goals
    @Published var calorieGoal: String = "2500"
    @Published var proteinGoal: String = "180"
    @Published var carbsGoal: String = "300"
    @Published var fatGoal: String = "80"
    
    @Published var currentStep = 0
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var shouldDismiss = false
    @Published var existingProfile: UserProfile?
    @Published var requiredSteps: [OnboardingStep] = []
    
    // Unhashed nonce for Apple Sign In
    private var currentNonce: String?
    
    private let firebaseService = FirebaseService.shared
    
    enum OnboardingStep: Int, CaseIterable {
        case accountInfo
        case personalInfo
        case bodyMeasurements
        case nutritionGoals
    }
    
    init() {
        Task {
            await loadExistingProfile()
        }
    }
    
    private func loadExistingProfile() async {
        do {
            existingProfile = try await firebaseService.getUserProfile()
            determineRequiredSteps()
        } catch {
            print("Error loading profile: \(error)")
            requiredSteps = OnboardingStep.allCases
        }
    }
    
    private func determineRequiredSteps() {
        guard let profile = existingProfile else {
            requiredSteps = OnboardingStep.allCases
            return
        }
        
        var steps: [OnboardingStep] = []
        
        // Check which information is missing
        if profile.username.isEmpty || profile.fullName.isEmpty {
            steps.append(.accountInfo)
        }
        
        if profile.gender == .preferNotToSay {
            steps.append(.personalInfo)
        }
        
        if profile.height == 0 || profile.weight == 0 {
            steps.append(.bodyMeasurements)
        }
        
        // Always add nutrition goals if they're missing or zero
        if profile.dailyCalorieGoal == 0 || profile.dailyProteinGoal == 0 || 
           profile.dailyCarbsGoal == 0 || profile.dailyFatGoal == 0 {
            steps.append(.nutritionGoals)
        }
        
        requiredSteps = steps.isEmpty ? [.nutritionGoals] : steps
        
        // Pre-fill existing data
        username = profile.username
        fullName = profile.fullName
        birthDate = profile.birthDate
        gender = profile.gender
        height = String(format: "%.0f", profile.height)
        weight = String(format: "%.0f", profile.weight)
    }
    
    var isValidUsername: Bool {
        username.count >= 3 && username.count <= 20
    }
    
    var isValidFullName: Bool {
        fullName.count >= 2
    }
    
    var isValidHeight: Bool {
        guard let height = Double(height) else { return false }
        return height >= 100 && height <= 250
    }
    
    var isValidWeight: Bool {
        guard let weight = Double(weight) else { return false }
        return weight >= 30 && weight <= 300
    }
    
    var isValidNutritionGoals: Bool {
        guard let calories = Int(calorieGoal),
              let protein = Int(proteinGoal),
              let carbs = Int(carbsGoal),
              let fat = Int(fatGoal) else {
            return false
        }
        
        return calories >= 1200 && calories <= 5000 &&
               protein >= 30 && protein <= 400 &&
               carbs >= 50 && carbs <= 600 &&
               fat >= 20 && fat <= 200
    }
    
    var canProceedToNextStep: Bool {
        guard let currentStepIndex = requiredSteps.firstIndex(where: { $0.rawValue == currentStep }) else {
            return false
        }
        
        switch requiredSteps[currentStepIndex] {
        case .accountInfo:
            return isValidUsername && isValidFullName
        case .personalInfo:
            return true
        case .bodyMeasurements:
            return isValidHeight && isValidWeight
        case .nutritionGoals:
            return isValidNutritionGoals
        }
    }
    
    func nextStep() {
        if let currentIndex = requiredSteps.firstIndex(where: { $0.rawValue == currentStep }),
           currentIndex < requiredSteps.count - 1 {
            currentStep = requiredSteps[currentIndex + 1].rawValue
        }
    }
    
    func previousStep() {
        if let currentIndex = requiredSteps.firstIndex(where: { $0.rawValue == currentStep }),
           currentIndex > 0 {
            currentStep = requiredSteps[currentIndex - 1].rawValue
        }
    }
    
    func calculateRecommendedCalories() {
        guard let weightKg = Double(weight),
              let heightCm = Double(height) else {
            return
        }
        
        // Bereken basaal metabolisme (BMR) met Harris-Benedict formule
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 25
        
        var bmr: Double
        
        switch gender {
        case .male:
            bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(age))
        case .female:
            bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(age))
        default:
            // Gebruik gemiddelde voor andere genders
            let maleBmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(age))
            let femaleBmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(age))
            bmr = (maleBmr + femaleBmr) / 2
        }
        
        // Vermenigvuldig met activiteitsfactor (gemiddeld = 1.55)
        let tdee = bmr * 1.55
        
        // Update de doelen
        calorieGoal = String(format: "%.0f", tdee)
        proteinGoal = String(format: "%.0f", weightKg * 2.2) // 2.2g per kg lichaamsgewicht
        carbsGoal = String(format: "%.0f", tdee * 0.45 / 4) // 45% van calorieën uit koolhydraten
        fatGoal = String(format: "%.0f", tdee * 0.25 / 9) // 25% van calorieën uit vetten
    }
    
    func saveProfile() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Geen gebruiker gevonden"
            showError = true
            return
        }
        
        guard let calorieGoalValue = Int(calorieGoal),
              let proteinGoalValue = Int(proteinGoal),
              let carbsGoalValue = Int(carbsGoal),
              let fatGoalValue = Int(fatGoal) else {
            errorMessage = "Ongeldige waarden"
            showError = true
            return
        }
        
        isLoading = true
        
        // Create or update profile based on existing data
        let profile: UserProfile
        if let existingProfile = existingProfile {
            // Update existing profile
            profile = UserProfile(
                id: existingProfile.id,
                name: existingProfile.name,
                email: existingProfile.email,
                username: username,
                createdAt: existingProfile.createdAt,
                preferences: existingProfile.preferences,
                fullName: fullName,
                height: Double(height) ?? existingProfile.height,
                weight: Double(weight) ?? existingProfile.weight,
                dailyCalorieGoal: calorieGoalValue,
                dailyProteinGoal: proteinGoalValue,
                dailyCarbsGoal: carbsGoalValue,
                dailyFatGoal: fatGoalValue,
                gender: gender,
                birthDate: birthDate,
                foodEntries: existingProfile.foodEntries
            )
        } else {
            // Create new profile
            profile = UserProfile(
                id: user.uid,
                name: fullName,
                email: user.email ?? "",
                username: username,
                createdAt: Date(),
                preferences: [:],
                fullName: fullName,
                height: Double(height) ?? 0,
                weight: Double(weight) ?? 0,
                dailyCalorieGoal: calorieGoalValue,
                dailyProteinGoal: proteinGoalValue,
                dailyCarbsGoal: carbsGoalValue,
                dailyFatGoal: fatGoalValue,
                gender: gender,
                birthDate: birthDate
            )
        }
        
        do {
            print("💾 Attempting to save profile for user: \(user.uid)")
            try await firebaseService.saveUserProfile(profile)
            print("✅ Profile saved successfully")
            shouldDismiss = true
        } catch {
            print("❌ Error saving profile: \(error.localizedDescription)")
            errorMessage = "Er ging iets mis bij het opslaan van je profiel"
            showError = true
        }
        
        isLoading = false
    }
    
    // Generate random nonce for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    // Hash the nonce for Apple Sign In
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // Handle Apple Sign In Request
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    // Handle Apple Sign In Completion
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                guard let nonce = currentNonce else {
                    print("Invalid state: A login callback was received, but no login request was sent.")
                    return
                }
                
                Task {
                    do {
                        let credential = OAuthProvider.credential(
                            withProviderID: "apple.com",
                            idToken: idTokenString,
                            rawNonce: nonce
                        )
                        
                        try await Auth.auth().signIn(with: credential)
                        await MainActor.run {
                            self.shouldDismiss = true
                        }
                    } catch {
                        await MainActor.run {
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    }
                }
            }
        case .failure(let error):
            print(error.localizedDescription)
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseAuth.Auth.auth().app?.options.clientID else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get client ID"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get root view controller"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get ID token"])
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await Auth.auth().signIn(with: credential)
        self.shouldDismiss = true
    }
} 