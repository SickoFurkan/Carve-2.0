import SwiftUI
import AuthenticationServices

// MARK: - Name Input Step
struct NameInputStepView: View {
    @Binding var firstName: String
    @Binding var currentStep: Int
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Welcome")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Let's get to know each other 😊")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                    
                    Text("What's your name?")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                
                TextField("First name", text: $firstName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 40)
                    .focused($isNameFieldFocused)
                    .foregroundColor(.black)
                    .submitLabel(.continue)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(action: {
                                if !firstName.isEmpty {
                                    withAnimation(.easeInOut) {
                                        currentStep = 2
                                    }
                                }
                            }) {
                                Text("Continue")
                                    .font(.headline)
                                    .foregroundColor(!firstName.isEmpty ? .white : .gray)
                                    .frame(width: 100, height: 36)
                                    .background(!firstName.isEmpty ? Color.blue : Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                            }
                            .disabled(firstName.isEmpty)
                        }
                    }
            }
            .padding(.top, 40)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98))
    }
}

// MARK: - Motivation Step
struct MotivationStepView: View {
    let firstName: String
    @Binding var selectedMotivation: String?
    @Binding var currentStep: Int
    let motivations: [String]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Hello \(firstName)!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("What brings you here?")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(motivations, id: \.self) { motivation in
                    Button {
                        withAnimation(.easeInOut) {
                            selectedMotivation = motivation
                            currentStep = 3
                        }
                    } label: {
                        Text(motivation)
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedMotivation == motivation ? Color.blue.opacity(0.1) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedMotivation == motivation ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 40)
        }
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98))
    }
}

// MARK: - Basic Info Step
struct BasicInfoStepView: View {
    @Binding var age: String
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(spacing: 16) {
                Text("Basic Information")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Text("Select your age")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                VerticalSlider(
                    title: "Age (years)",
                    value: Binding(
                        get: { Double(age) ?? 25 },
                        set: { age = String(Int($0)) }
                    ),
                    range: 13...100,
                    step: 1,
                    unit: " years"
                )
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        currentStep = 4
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Measurements Step
struct MeasurementsStepView: View {
    @Binding var height: String
    @Binding var weight: String
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(spacing: 16) {
                Text("Measurements")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Text("Enter your height and weight")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                TextField("Height (cm)", text: $height)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 40)
                    .foregroundColor(.black)
                    .submitLabel(.continue)
                
                TextField("Weight (kg)", text: $weight)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 40)
                    .foregroundColor(.black)
                    .submitLabel(.continue)
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        currentStep = 5
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Gender Step
struct GenderStepView: View {
    @Binding var selectedGender: Gender
    @Binding var currentStep: Int
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    let onGenderSelected: () async -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(spacing: 16) {
                Text("Gender")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Text("Select your gender")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                ForEach(Gender.allCases) { gender in
                    Button {
                        selectedGender = gender
                        Task {
                            await onGenderSelected()
                        }
                    } label: {
                        Text(gender.rawValue)
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedGender == gender ? Color.blue.opacity(0.1) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedGender == gender ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - Authentication Step
struct AuthenticationStepView: View {
    @Binding var showPhoneAuth: Bool
    @Binding var phoneNumber: String
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    let viewModel: OnboardingViewModel
    let onPhoneVerificationComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(spacing: 16) {
                Text("Authentication")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Text("Enter your phone number to verify")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                TextField("Phone number", text: $phoneNumber)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 40)
                    .foregroundColor(.black)
                    .submitLabel(.continue)
                
                Button(action: {
                    showPhoneAuth = true
                    onPhoneVerificationComplete()
                }) {
                    Text("Send verification code")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
} 