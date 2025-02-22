import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

struct OnboardingNameView: View {
    @StateObject private var viewModel = OnboardingNameViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ProgressBarView(currentStep: viewModel.currentStep)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    StepContentView(viewModel: viewModel, isPresented: $isPresented)
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
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
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

// MARK: - Supporting Views
private struct ProgressBarView: View {
    let currentStep: Int
    
    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 2)
                
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: 120 * CGFloat(currentStep) / 7, height: 2)
            }
            .frame(width: 120)
            
            Text("Step \(currentStep) of 7")
                .foregroundColor(.black)
                .frame(width: 100, alignment: .trailing)
        }
    }
}

private struct StepContentView: View {
    @ObservedObject var viewModel: OnboardingNameViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
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
                            try await viewModel.createProfile(using: FirebaseService.shared)
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
                viewModel: viewModel,
                onPhoneVerificationComplete: {
                    Task {
                        await viewModel.sendVerificationCode()
                    }
                }
            )
        case 7:
            UsernameSelectionStepView(
                firstName: viewModel.firstName,
                username: $viewModel.username,
                isUsernameValid: viewModel.isUsernameValid,
                isCheckingUsername: viewModel.isCheckingUsername,
                validationMessages: viewModel.usernameValidationMessages,
                onUsernameChanged: { newValue in
                    Task {
                        await viewModel.validateUsername(newValue)
                    }
                },
                onComplete: {
                    Task {
                        await viewModel.finalizeProfile()
                    }
                }
            )
        default:
            EmptyView()
        }
    }
}

#Preview {
    OnboardingNameView(isPresented: .constant(true))
} 
