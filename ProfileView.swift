import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingLogoutAlert = false
    @State private var showingOnboarding = false
    @EnvironmentObject private var firebaseService: FirebaseService
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(firebaseService: FirebaseService.shared))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Profiel laden...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Kon profielgegevens niet laden")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        // Debug button
                        Button(action: {
                            firebaseService.debugCheckUserStatus()
                        }) {
                            Label("Check Firebase Status", systemImage: "magnifyingglass")
                                .foregroundColor(.blue)
                        }
                        .padding(.top)
                        
                        // Start Onboarding button
                        Button(action: {
                            showingOnboarding = true
                        }) {
                            Label("Profiel aanmaken", systemImage: "person.badge.plus")
                                .foregroundColor(.green)
                        }
                        .padding(.top)
                        
                        Button("Opnieuw proberen") {
                            Task {
                                await viewModel.loadUserProfile()
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                } else if let profile = viewModel.userProfile {
                    // Profile Header
                    CardView {
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            if viewModel.isEditing {
                                TextField("Volledige naam", text: $viewModel.editedProfile.fullName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                    .font(.title)
                            } else {
                                Text(profile.fullName)
                                    .font(.title)
                                    .bold()
                            }
                            
                            HStack(spacing: 20) {
                                if viewModel.isEditing {
                                    StatView(value: viewModel.editedProfile.weight, unit: "kg")
                                    StatView(value: viewModel.editedProfile.height, unit: "cm")
                                    StatView(value: String(format: "%.1f", viewModel.calculateBMI()), unit: "BMI")
                                } else {
                                    StatView(value: String(format: "%.0f", profile.weight), unit: "kg")
                                    StatView(value: String(format: "%.0f", profile.height), unit: "cm")
                                    StatView(value: String(format: "%.1f", profile.bmi), unit: "BMI")
                                }
                            }
                            
                            if !viewModel.isEditing {
                                Text(profile.bmiCategory.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Persoonlijke Informatie
                    CardView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Persoonlijke Informatie")
                                    .font(.headline)
                                Spacer()
                                if !viewModel.isEditing {
                                    Button(action: {
                                        viewModel.startEditing(profile: profile)
                                    }) {
                                        Text("Bewerken")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            if viewModel.isEditing {
                                EditableInfoRow(label: "Gebruikersnaam", text: $viewModel.editedProfile.username)
                                EditableInfoRow(label: "E-mail", text: .constant(profile.email))
                                    .disabled(true)
                                
                                Picker("Geslacht", selection: $viewModel.editedProfile.gender) {
                                    ForEach(Gender.allCases, id: \.self) { gender in
                                        Text(gender.rawValue).tag(gender)
                                    }
                                }
                                
                                DatePicker("Geboortedatum", 
                                         selection: $viewModel.editedProfile.birthDate,
                                         displayedComponents: .date)
                                
                                HStack {
                                    Text("Lengte")
                                    Spacer()
                                    TextField("Lengte", text: $viewModel.editedProfile.height)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                    Text("cm")
                                }
                                
                                HStack {
                                    Text("Gewicht")
                                    Spacer()
                                    TextField("Gewicht", text: $viewModel.editedProfile.weight)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                    Text("kg")
                                }
                                
                                Divider()
                                    .padding(.vertical)
                                
                                Text("Voedingsdoelen")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                                
                                Group {
                                    HStack {
                                        Text("Dagelijkse calorieën")
                                        Spacer()
                                        TextField("Calorieën", text: $viewModel.editedProfile.calorieGoal)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                        Text("kcal")
                                    }
                                    
                                    HStack {
                                        Text("Eiwitten")
                                        Spacer()
                                        TextField("Eiwitten", text: $viewModel.editedProfile.proteinGoal)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                        Text("g")
                                    }
                                    
                                    HStack {
                                        Text("Koolhydraten")
                                        Spacer()
                                        TextField("Koolhydraten", text: $viewModel.editedProfile.carbsGoal)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                        Text("g")
                                    }
                                    
                                    HStack {
                                        Text("Vetten")
                                        Spacer()
                                        TextField("Vetten", text: $viewModel.editedProfile.fatGoal)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                        Text("g")
                                    }
                                }
                                
                                Button("Bereken aanbevolen doelen") {
                                    viewModel.calculateRecommendedGoals()
                                }
                                .padding(.top)
                                
                                HStack {
                                    Button("Annuleren") {
                                        viewModel.isEditing = false
                                    }
                                    .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    Button("Opslaan") {
                                        Task {
                                            await viewModel.saveProfile()
                                        }
                                    }
                                    .foregroundColor(.blue)
                                }
                                .padding(.top)
                            } else {
                                InfoRow(label: "E-mail", value: profile.email)
                                InfoRow(label: "Gebruikersnaam", value: profile.username)
                                InfoRow(label: "Geslacht", value: profile.gender.rawValue)
                                InfoRow(label: "Geboortedatum", value: formatDate(profile.birthDate))
                            }
                        }
                    }
                    
                    // Uitloggen
                    CardView {
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            Text("Uitloggen")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Geen profielgegevens beschikbaar")
                            .font(.headline)
                        if !firebaseService.isAuthenticated {
                            Text("Je bent niet ingelogd")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Debug button
                        Button(action: {
                            firebaseService.debugCheckUserStatus()
                        }) {
                            Label("Check Firebase Status", systemImage: "magnifyingglass")
                                .foregroundColor(.blue)
                        }
                        .padding(.top)
                        
                        Button("Opnieuw proberen") {
                            Task {
                                await viewModel.loadUserProfile()
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .padding(.top)
        }
        .task {
            await viewModel.loadUserProfile()
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .alert("Uitloggen", isPresented: $showingLogoutAlert) {
            Button("Annuleren", role: .cancel) { }
            Button("Uitloggen", role: .destructive) {
                Task {
                    await firebaseService.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Weet je zeker dat je wilt uitloggen?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: date)
    }
}

struct EditableProfile {
    var username: String = ""
    var fullName: String = ""
    var birthDate: Date = Date()
    var gender: Gender = .preferNotToSay
    var height: String = ""
    var weight: String = ""
    var calorieGoal: String = ""
    var proteinGoal: String = ""
    var carbsGoal: String = ""
    var fatGoal: String = ""
    
    init(
        username: String = "",
        fullName: String = "",
        birthDate: Date = Date(),
        gender: Gender = .preferNotToSay,
        height: String = "",
        weight: String = "",
        calorieGoal: String = "",
        proteinGoal: String = "",
        carbsGoal: String = "",
        fatGoal: String = ""
    ) {
        self.username = username
        self.fullName = fullName
        self.birthDate = birthDate
        self.gender = gender
        self.height = height
        self.weight = weight
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var editedProfile = EditableProfile()
    
    private let firebaseService: FirebaseService
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
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
    
    func saveProfile() async {
        isLoading = true
        
        guard var updatedProfile = userProfile else {
            errorMessage = "Geen profiel gevonden om te updaten"
            isLoading = false
            return
        }
        
        // Update profile with edited values
        updatedProfile.username = editedProfile.username
        updatedProfile.fullName = editedProfile.fullName
        updatedProfile.birthDate = editedProfile.birthDate
        updatedProfile.gender = editedProfile.gender
        updatedProfile.height = Double(editedProfile.height) ?? updatedProfile.height
        updatedProfile.weight = Double(editedProfile.weight) ?? updatedProfile.weight
        updatedProfile.dailyCalorieGoal = Int(editedProfile.calorieGoal) ?? updatedProfile.dailyCalorieGoal
        updatedProfile.dailyProteinGoal = Int(editedProfile.proteinGoal) ?? updatedProfile.dailyProteinGoal
        updatedProfile.dailyCarbsGoal = Int(editedProfile.carbsGoal) ?? updatedProfile.dailyCarbsGoal
        updatedProfile.dailyFatGoal = Int(editedProfile.fatGoal) ?? updatedProfile.dailyFatGoal
        
        do {
            try await firebaseService.saveUserProfile(updatedProfile)
            userProfile = updatedProfile
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func startEditing(profile: UserProfile) {
        editedProfile = EditableProfile(
            username: profile.username,
            fullName: profile.fullName,
            birthDate: profile.birthDate,
            gender: profile.gender,
            height: String(format: "%.0f", profile.height),
            weight: String(format: "%.0f", profile.weight),
            calorieGoal: "\(profile.dailyCalorieGoal)",
            proteinGoal: "\(profile.dailyProteinGoal)",
            carbsGoal: "\(profile.dailyCarbsGoal)",
            fatGoal: "\(profile.dailyFatGoal)"
        )
        isEditing = true
    }
    
    func calculateBMI() -> Double {
        let height = Double(editedProfile.height) ?? 0
        let weight = Double(editedProfile.weight) ?? 0
        guard height > 0 else { return 0 }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    func calculateRecommendedGoals() {
        guard let weight = Double(editedProfile.weight) else { return }
        
        // Basic calculations based on weight
        editedProfile.proteinGoal = "\(Int(weight * 2))"  // 2g per kg bodyweight
        editedProfile.carbsGoal = "\(Int(weight * 3))"    // 3g per kg bodyweight
        editedProfile.fatGoal = "\(Int(weight * 1))"      // 1g per kg bodyweight
        
        // Calculate BMR using weight, height, age, and gender
        let height = Double(editedProfile.height) ?? 170
        let age = Calendar.current.dateComponents([.year], from: editedProfile.birthDate, to: Date()).year ?? 30
        
        var bmr: Double
        if editedProfile.gender == .male {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        // Multiply BMR by activity factor (using moderate activity = 1.55)
        let tdee = bmr * 1.55
        
        // Round to nearest 50
        let roundedCalories = Int(round(tdee / 50) * 50)
        editedProfile.calorieGoal = "\(roundedCalories)"
    }
}

struct EditableInfoRow: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            TextField(label, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .frame(width: 200)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(FirebaseService.shared)
} 