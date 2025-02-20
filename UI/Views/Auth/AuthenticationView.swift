import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthenticationView: View {
    @Binding var isPresented: Bool
    @Binding var showPhoneAuth: Bool
    @Binding var phoneNumber: String
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showError = false
    @State private var errorMessage: String?
    
    init(isPresented: Binding<Bool>, showPhoneAuth: Binding<Bool>, phoneNumber: Binding<String>, viewModel: OnboardingViewModel) {
        self._isPresented = isPresented
        self._showPhoneAuth = showPhoneAuth
        self._phoneNumber = phoneNumber
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(showPhoneAuth ? "Phone Verification" : "Final Step!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text(showPhoneAuth ? "Enter your phone number to continue" : "Choose how you want to sign in")
                    .font(.title3)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            if showPhoneAuth {
                // Phone Verification View
                VStack(spacing: 16) {
                    HStack {
                        Text("+31")
                            .foregroundColor(.black)
                            .font(.title3)
                        
                        TextField("Phone number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomTextFieldStyle())
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 32)
                    
                    Button(action: {
                        Task {
                            await sendVerificationCode()
                        }
                    }) {
                        Text("Send Code")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(phoneNumber.count >= 9 ? Color.blue : Color.gray)
                            .cornerRadius(16)
                    }
                    .disabled(phoneNumber.count < 9)
                    .padding(.horizontal, 32)
                    
                    Button(action: {
                        withAnimation {
                            showPhoneAuth = false
                            phoneNumber = ""
                        }
                    }) {
                        Text("Back")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
            } else {
                // Authentication Options
                VStack(spacing: 16) {
                    // Phone Number Sign In
                    Button {
                        withAnimation {
                            showPhoneAuth = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.title2)
                            Text("Continue with Phone")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    
                    // Google Sign In
                    Button {
                        Task {
                            do {
                                try await viewModel.signInWithGoogle()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Continue with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    
                    // Apple Sign In
                    SignInWithAppleButton { request in
                        viewModel.handleAppleSignInRequest(request)
                    } onCompletion: { result in
                        viewModel.handleAppleSignInCompletion(result)
                        if case .success = result {
                            withAnimation(.easeInOut) {
                                isPresented = false
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
                }
            }
            
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func sendVerificationCode() async {
        let phoneAuthViewModel = PhoneAuthViewModel()
        phoneAuthViewModel.phoneNumber = phoneNumber
        await phoneAuthViewModel.sendVerificationCode()
        
        if phoneAuthViewModel.isAuthenticated {
            withAnimation(.easeInOut) {
                isPresented = false
            }
        }
    }
} 