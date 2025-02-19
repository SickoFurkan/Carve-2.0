import SwiftUI

enum ProfileSetupStep: Int, CaseIterable, Hashable {
    case personalInfo
    case bodyMeasurements
    case nutritionGoals
    
    var title: String {
        switch self {
        case .personalInfo: return "Personal Information"
        case .bodyMeasurements: return "Body Measurements"
        case .nutritionGoals: return "Daily Goals"
        }
    }
    
    var systemImage: String {
        switch self {
        case .personalInfo: return "person.fill"
        case .bodyMeasurements: return "figure.arms.open"
        case .nutritionGoals: return "chart.bar.fill"
        }
    }
}

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firebaseService: FirebaseService
    @StateObject private var viewModel = ProfileSetupViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Indicator
                if !viewModel.requiredSteps.isEmpty {
                    HStack(spacing: 15) {
                        ForEach(viewModel.orderedSteps, id: \.self) { step in
                            StepIndicator(
                                step: step,
                                isActive: step == viewModel.currentStep,
                                isCompleted: viewModel.completedSteps.contains(step)
                            )
                        }
                    }
                    .padding(.top)
                }
                
                // Current Step Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.currentStep {
                        case .personalInfo:
                            PersonalInfoView(viewModel: viewModel)
                        case .bodyMeasurements:
                            ProfileBodyMeasurementsView(viewModel: viewModel)
                        case .nutritionGoals:
                            NutritionGoalsView(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
                
                // Navigation Buttons
                if !viewModel.requiredSteps.isEmpty {
                    HStack(spacing: 20) {
                        if viewModel.canGoBack {
                            Button(action: viewModel.previousStep) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                if viewModel.isLastStep {
                                    if await viewModel.saveProfile() {
                                        dismiss()
                                    }
                                } else {
                                    viewModel.nextStep()
                                }
                            }
                        }) {
                            HStack {
                                Text(viewModel.isLastStep ? "Save" : "Next")
                                if !viewModel.isLastStep {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.canProceedFromCurrentStep)
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .task {
                await viewModel.loadExistingProfile()
            }
        }
    }
}

struct StepIndicator: View {
    let step: ProfileSetupStep
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: step.systemImage)
                        .foregroundColor(isActive ? .white : .gray)
                }
            }
            
            Text(step.title)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

struct PersonalInfoView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TextField("Full name", text: $viewModel.fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.name)
            
            DatePicker("Date of birth", selection: $viewModel.birthDate, displayedComponents: .date)
            
            Picker("Gender", selection: $viewModel.gender) {
                ForEach(UserGender.allCases, id: \.self) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct ProfileBodyMeasurementsView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                TextField("Height", text: $viewModel.height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Text("cm")
            }
            
            HStack {
                TextField("Weight", text: $viewModel.weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Text("kg")
            }
        }
    }
}

struct NutritionGoalsView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                TextField("Calories", text: $viewModel.calorieGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Text("kcal")
            }
            
            HStack {
                TextField("Protein", text: $viewModel.proteinGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Text("g")
            }
            
            HStack {
                TextField("Carbs", text: $viewModel.carbsGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Text("g")
            }
            
            HStack {
                TextField("Fat", text: $viewModel.fatGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Text("g")
            }
        }
    }
}

@MainActor
class ProfileSetupViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var birthDate = Date()
    @Published var gender: UserGender = .preferNotToSay
    @Published var height = ""
    @Published var weight = ""
    @Published var calorieGoal = "2500"
    @Published var proteinGoal = "180"
    @Published var carbsGoal = "300"
    @Published var fatGoal = "80"
    @Published var showError = false
    @Published var errorMessage: String?
    @Published private(set) var requiredSteps: Set<ProfileSetupStep> = []
    @Published private(set) var completedSteps: Set<ProfileSetupStep> = []
    @Published private(set) var currentStep: ProfileSetupStep = .personalInfo
    @Published private(set) var isNewProfile = true
    
    private let firebaseService = FirebaseService.shared
    
    var navigationTitle: String {
        isNewProfile ? "Create Profile" : "Complete Profile"
    }
    
    var orderedSteps: [ProfileSetupStep] {
        requiredSteps.sorted(by: { $0.rawValue < $1.rawValue })
    }
    
    var isLastStep: Bool {
        guard let lastStep = orderedSteps.last else { return true }
        return currentStep == lastStep
    }
    
    var canGoBack: Bool {
        guard let firstStep = orderedSteps.first else { return false }
        return currentStep != firstStep
    }
    
    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case .personalInfo:
            return !fullName.isEmpty
        case .bodyMeasurements:
            return !height.isEmpty && Double(height) ?? 0 > 0 &&
                   !weight.isEmpty && Double(weight) ?? 0 > 0
        case .nutritionGoals:
            return !calorieGoal.isEmpty && Int(calorieGoal) ?? 0 > 0 &&
                   !proteinGoal.isEmpty && Int(proteinGoal) ?? 0 > 0 &&
                   !carbsGoal.isEmpty && Int(carbsGoal) ?? 0 > 0 &&
                   !fatGoal.isEmpty && Int(fatGoal) ?? 0 > 0
        }
    }
    
    func nextStep() {
        if canProceedFromCurrentStep {
            completedSteps.insert(currentStep)
            if let currentIndex = orderedSteps.firstIndex(of: currentStep),
               currentIndex + 1 < orderedSteps.count {
                currentStep = orderedSteps[currentIndex + 1]
            }
        }
    }
    
    func previousStep() {
        if let currentIndex = orderedSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            currentStep = orderedSteps[currentIndex - 1]
        }
    }
    
    func loadExistingProfile() async {
        do {
            if let profile = try await firebaseService.getUserProfile() {
                isNewProfile = false
                await MainActor.run {
                    // Load existing values
                    fullName = profile.fullName
                    birthDate = profile.birthDate
                    gender = profile.gender
                    height = String(format: "%.0f", profile.height)
                    weight = String(format: "%.0f", profile.weight)
                    calorieGoal = "\(profile.dailyCalorieGoal)"
                    proteinGoal = "\(profile.dailyProteinGoal)"
                    carbsGoal = "\(profile.dailyCarbsGoal)"
                    fatGoal = "\(profile.dailyFatGoal)"
                    
                    // Determine which steps are required
                    requiredSteps = []
                    
                    if profile.fullName.isEmpty {
                        requiredSteps.insert(.personalInfo)
                    }
                    
                    if profile.height <= 0 || profile.weight <= 0 {
                        requiredSteps.insert(.bodyMeasurements)
                    }
                    
                    if profile.dailyCalorieGoal <= 0 || profile.dailyProteinGoal <= 0 ||
                       profile.dailyCarbsGoal <= 0 || profile.dailyFatGoal <= 0 {
                        requiredSteps.insert(.nutritionGoals)
                    }
                    
                    // Set initial step
                    if let firstStep = orderedSteps.first {
                        currentStep = firstStep
                    }
                }
            } else {
                isNewProfile = true
                requiredSteps = Set(ProfileSetupStep.allCases)
                currentStep = .personalInfo
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isNewProfile = true
            requiredSteps = Set(ProfileSetupStep.allCases)
            currentStep = .personalInfo
        }
    }
    
    func saveProfile() async -> Bool {
        guard let userId = firebaseService.user?.id else {
            errorMessage = "No user found"
            showError = true
            return false
        }
        
        do {
            let existingProfile = try await firebaseService.getUserProfile()
            
            // Create base profile
            let baseProfile = existingProfile ?? UserProfile(
                id: userId,
                name: fullName,
                email: firebaseService.user?.email ?? "",
                username: firebaseService.user?.email?.components(separatedBy: "@").first ?? "",
                createdAt: Date(),
                preferences: [:],
                fullName: fullName,
                height: Double(height) ?? 0,
                weight: Double(weight) ?? 0,
                dailyCalorieGoal: Int(calorieGoal) ?? 2000,
                dailyProteinGoal: Int(proteinGoal) ?? 150,
                dailyCarbsGoal: Int(carbsGoal) ?? 250,
                dailyFatGoal: Int(fatGoal) ?? 65,
                gender: gender,
                birthDate: birthDate
            )
            
            // Create new profile with updated fields based on required steps
            let updatedProfile = UserProfile(
                id: baseProfile.id,
                name: baseProfile.name,
                email: baseProfile.email,
                username: baseProfile.username,
                createdAt: baseProfile.createdAt,
                preferences: baseProfile.preferences,
                fullName: requiredSteps.contains(.personalInfo) ? fullName : baseProfile.fullName,
                height: requiredSteps.contains(.bodyMeasurements) ? (Double(height) ?? baseProfile.height) : baseProfile.height,
                weight: requiredSteps.contains(.bodyMeasurements) ? (Double(weight) ?? baseProfile.weight) : baseProfile.weight,
                dailyCalorieGoal: requiredSteps.contains(.nutritionGoals) ? (Int(calorieGoal) ?? baseProfile.dailyCalorieGoal) : baseProfile.dailyCalorieGoal,
                dailyProteinGoal: requiredSteps.contains(.nutritionGoals) ? (Int(proteinGoal) ?? baseProfile.dailyProteinGoal) : baseProfile.dailyProteinGoal,
                dailyCarbsGoal: requiredSteps.contains(.nutritionGoals) ? (Int(carbsGoal) ?? baseProfile.dailyCarbsGoal) : baseProfile.dailyCarbsGoal,
                dailyFatGoal: requiredSteps.contains(.nutritionGoals) ? (Int(fatGoal) ?? baseProfile.dailyFatGoal) : baseProfile.dailyFatGoal,
                gender: requiredSteps.contains(.personalInfo) ? gender : baseProfile.gender,
                birthDate: requiredSteps.contains(.personalInfo) ? birthDate : baseProfile.birthDate,
                foodEntries: baseProfile.foodEntries
            )
            
            try await firebaseService.saveUserProfile(updatedProfile)
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
} 
