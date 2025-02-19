import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

@MainActor
class OnboardingNameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var firstName: String = ""
    @Published var username: String = ""
    @Published var usernameValidationMessages: [ValidationMessage] = []
    @Published var isUsernameValid = false
    @Published var isCheckingUsername = false
    @Published var age: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var selectedMotivation: String?
    @Published var currentStep: Int = 1
    @Published var showLogin: Bool = false
    @Published var showPhoneAuth: Bool = false
    @Published var phoneNumber: String = ""
    @Published var selectedGender: UserGender = .preferNotToSay
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var isSaving: Bool = false
    @Published var shouldDismiss: Bool = false
    
    // MARK: - Constants
    let motivations = [
        "Lose weight",
        "Gain muscle and lose fat",
        "Gain muscle, fat loss is secondary",
        "Eat healthier without losing weight"
    ]
    
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Username Validation
    func validateUsername(_ username: String) async {
        isCheckingUsername = true
        var messages: [ValidationMessage] = []
        var isValidUsername = true
        
        // Length check
        let lengthValid = username.count >= 3 && username.count <= 20
        messages.append(ValidationMessage(
            text: "Between 3 and 20 characters",
            isValid: lengthValid
        ))
        isValidUsername = isValidUsername && lengthValid
        
        // Character check
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")
        let hasOnlyAllowedChars = username.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        messages.append(ValidationMessage(
            text: "Only letters, numbers, dots, and underscores",
            isValid: hasOnlyAllowedChars
        ))
        isValidUsername = isValidUsername && hasOnlyAllowedChars
        
        // Start check
        let startsWithLetterOrNumber = username.first?.isLetter ?? false || username.first?.isNumber ?? false
        messages.append(ValidationMessage(
            text: "Must start with a letter or number",
            isValid: startsWithLetterOrNumber
        ))
        isValidUsername = isValidUsername && startsWithLetterOrNumber
        
        if isValidUsername {
            do {
                let isAvailable = try await firebaseService.isUsernameAvailable(username)
                messages.append(ValidationMessage(
                    text: "Username is available",
                    isValid: isAvailable
                ))
                isValidUsername = isValidUsername && isAvailable
            } catch {
                messages.append(ValidationMessage(
                    text: "Could not check availability",
                    isValid: false
                ))
                isValidUsername = false
            }
        }
        
        await MainActor.run {
            usernameValidationMessages = messages
            isUsernameValid = isValidUsername
            isCheckingUsername = false
        }
    }
    
    // MARK: - Profile Management
    func createProfile(using firebaseService: FirebaseService) async throws {
        guard let heightValue = Double(height),
              let weightValue = Double(weight),
              let ageValue = Int(age) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid measurements"])
        }
        
        let birthDate = Calendar.current.date(byAdding: .year, value: -ageValue, to: Date()) ?? Date()
        
        let preferences: [String: String] = [
            "motivation": selectedMotivation ?? "",
            "birthDate": ISO8601DateFormatter().string(from: birthDate),
            "gender": selectedGender.rawValue
        ]
        
        let profile = UserProfile(
            id: UUID().uuidString,
            name: firstName,
            email: "",  // Will be updated after authentication
            username: username,
            createdAt: Date(),
            preferences: preferences,
            fullName: firstName,
            height: heightValue,
            weight: weightValue,
            dailyCalorieGoal: calculateDailyCalorieGoal(
                age: ageValue,
                gender: selectedGender,
                height: heightValue,
                weight: weightValue
            )
        )
        
        try await firebaseService.saveUserProfile(profile)
    }
    
    func sendVerificationCode() async {
        let phoneAuthViewModel = PhoneAuthViewModel()
        phoneAuthViewModel.phoneNumber = phoneNumber
        await phoneAuthViewModel.sendVerificationCode()
        
        if phoneAuthViewModel.isAuthenticated {
            do {
                try await createProfile(using: firebaseService)
                withAnimation {
                    currentStep = 7 // Move to username selection
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func finalizeProfile() async {
        isSaving = true
        
        do {
            guard let userId = firebaseService.user?.id else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            try await firebaseService.updateUsername(userId: userId, newUsername: username)
            showOnboarding = false
            shouldDismiss = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSaving = false
    }
    
    // MARK: - Helper Methods
    private func calculateDailyCalorieGoal(age: Int, gender: UserGender, height: Double, weight: Double) -> Int {
        var bmr: Double
        switch gender {
        case .male:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        case .female:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        case .preferNotToSay, .other:
            let maleBmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
            let femaleBmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
            bmr = (maleBmr + femaleBmr) / 2
        }
        
        return Int(bmr * 1.55)
    }
} 