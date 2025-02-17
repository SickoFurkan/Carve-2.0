import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

@MainActor
class OnboardingNameViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var age: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var selectedMotivation: String?
    @Published var currentStep: Int = 1
    @Published var showLogin: Bool = false
    @Published var showPhoneAuth: Bool = false
    @Published var phoneNumber: String = ""
    @Published var selectedGender: Gender = .preferNotToSay
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var showOnboarding: Bool = false
    
    let motivations = [
        "Lose weight",
        "Gain muscle and lose fat",
        "Gain muscle, fat loss is secondary",
        "Eat healthier without losing weight"
    ]
    
    func createProfile(using firebaseService: FirebaseService) async throws {
        guard let heightValue = Double(height),
              let weightValue = Double(weight),
              let ageValue = Int(age) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid measurements"])
        }
        
        let birthDate = Calendar.current.date(byAdding: .year, value: -ageValue, to: Date()) ?? Date()
        
        let profile = UserProfile(
            id: UUID().uuidString,
            email: "",
            username: firstName.lowercased(),
            fullName: firstName,
            birthDate: birthDate,
            gender: selectedGender,
            height: heightValue,
            weight: weightValue,
            createdAt: Date()
        )
        
        try await firebaseService.saveUserProfile(profile)
    }
    
    func sendVerificationCode() async {
        let phoneAuthViewModel = PhoneAuthViewModel()
        phoneAuthViewModel.phoneNumber = phoneNumber
        await phoneAuthViewModel.sendVerificationCode()
        
        if phoneAuthViewModel.isAuthenticated {
            do {
                try await createProfile(using: FirebaseService.shared)
                showOnboarding = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct OnboardingNameView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = OnboardingNameViewModel()
    @StateObject private var authViewModel = OnboardingViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var firebaseService: FirebaseService
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    HStack {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(height: 2)
                            
                            Rectangle()
                                .foregroundColor(.blue)
                                .frame(width: 120 * CGFloat(viewModel.currentStep) / 6, height: 2)
                        }
                        .frame(width: 120)
                        
                        Text("Step \(viewModel.currentStep) of 6")
                            .foregroundColor(.black)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Content Views
                    switch viewModel.currentStep {
                    case 1:
                        NameInputStepView(
                            firstName: $viewModel.firstName,
                            currentStep: $viewModel.currentStep
                        )
                    case 2:
                        MotivationStepView(
                            firstName: viewModel.firstName,
                            selectedMotivation: $viewModel.selectedMotivation,
                            currentStep: $viewModel.currentStep,
                            motivations: viewModel.motivations
                        )
                    case 3:
                        BasicInfoStepView(
                            age: $viewModel.age,
                            currentStep: $viewModel.currentStep
                        )
                    case 4:
                        MeasurementsStepView(
                            height: $viewModel.height,
                            weight: $viewModel.weight,
                            currentStep: $viewModel.currentStep
                        )
                    case 5:
                        GenderStepView(
                            selectedGender: $viewModel.selectedGender,
                            currentStep: $viewModel.currentStep,
                            showError: $viewModel.showError,
                            errorMessage: $viewModel.errorMessage,
                            onGenderSelected: {
                                Task {
                                    do {
                                        try await viewModel.createProfile(using: firebaseService)
                                        withAnimation {
                                            viewModel.currentStep = 6
                                        }
                                    } catch {
                                        viewModel.errorMessage = error.localizedDescription
                                        viewModel.showError = true
                                    }
                                }
                            }
                        )
                    case 6:
                        AuthenticationStepView(
                            showPhoneAuth: $viewModel.showPhoneAuth,
                            phoneNumber: $viewModel.phoneNumber,
                            showError: $viewModel.showError,
                            errorMessage: $viewModel.errorMessage,
                            viewModel: authViewModel,
                            onPhoneVerificationComplete: {
                                Task {
                                    await viewModel.sendVerificationCode()
                                }
                            }
                        )
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 0.85)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                .padding(.top, geometry.safeAreaInsets.top + 20)
            }
            
            if viewModel.showLogin {
                LoginView(isPresented: $viewModel.showLogin, showOnboarding: $isPresented)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
            
            if viewModel.showPhoneAuth {
                PhoneAuthView(isPresented: $viewModel.showPhoneAuth)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .ignoresSafeArea()
        .onChange(of: authViewModel.shouldDismiss) { _, newValue in
            if newValue {
                isPresented = false
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
} 