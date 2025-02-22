import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingLogoutAlert = false
    @State private var showingOnboarding = false
    @EnvironmentObject private var firebaseService: FirebaseService
    @State private var showLanguageSelection = false
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(firebaseService: FirebaseService.shared))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Profiel laden...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        ProfileErrorView(
                            error: error,
                            firebaseService: firebaseService,
                            showingOnboarding: $showingOnboarding,
                            onRetry: {
                                Task {
                                    await viewModel.loadUserProfile()
                                }
                            }
                        )
                    } else if let profile = viewModel.userProfile {
                        profileContent(profile)
                    } else {
                        noProfileContent
                    }
                }
            }
            .padding(.top)
            .navigationTitle(NSLocalizedString("profile", comment: ""))
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
            .sheet(isPresented: $showLanguageSelection) {
                LanguageSelectionView()
            }
        }
    }
    
    private func profileContent(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Profile Header
            CardView {
                ProfileHeaderView(viewModel: viewModel, profile: profile)
            }
            
            // Personal Information
            CardView {
                personalInformationSection(profile)
            }
            
            // Language Settings
            CardView {
                languageSection
            }
            
            // Logout
            CardView {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    Text("Uitloggen")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func personalInformationSection(_ profile: UserProfile) -> some View {
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
                editingContent(profile)
            } else {
                displayContent(profile)
            }
        }
    }
    
    private func editingContent(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            InfoRow(label: "Gebruikersnaam", editableValue: $viewModel.tempUsername)
            InfoRow(label: "E-mail", editableValue: .constant(profile.email), isDisabled: true)
            
            Picker("Geslacht", selection: $viewModel.tempGender) {
                ForEach(UserGender.allCases, id: \.self) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            }
            
            DatePicker("Geboortedatum", 
                     selection: $viewModel.tempBirthDate,
                     displayedComponents: .date)
            
            HStack {
                Text("Lengte")
                Spacer()
                TextField("Lengte", text: $viewModel.tempHeight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                Text("cm")
            }
            
            HStack {
                Text("Gewicht")
                Spacer()
                TextField("Gewicht", text: $viewModel.tempWeight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                Text("kg")
            }
            
            Divider()
                .padding(.vertical)
            
            NutritionalGoalsSection(viewModel: viewModel)
            
            HStack {
                Button("Annuleren") {
                    viewModel.isEditing = false
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Opslaan") {
                    Task {
                        await viewModel.saveCurrentChanges()
                    }
                }
                .foregroundColor(.blue)
            }
            .padding(.top)
        }
    }
    
    private func displayContent(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(label: "E-mail", value: profile.email)
            InfoRow(label: "Gebruikersnaam", value: profile.username)
            InfoRow(label: "Geslacht", value: profile.gender.rawValue)
            InfoRow(label: "Geboortedatum", value: formatDate(profile.birthDate))
        }
    }
    
    private var languageSection: some View {
        Button(action: {
            showLanguageSelection = true
        }) {
            HStack {
                Text(languageManager.currentLanguage.flag)
                    .font(.title2)
                Text(languageManager.currentLanguage.displayName)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var noProfileContent: some View {
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: date)
    }
}

#Preview {
    ProfileView()
        .environmentObject(FirebaseService.shared)
} 
