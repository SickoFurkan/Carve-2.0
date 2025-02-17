import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @Binding var isPresented: Bool
    @Binding var showOnboarding: Bool
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPhoneAuth = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Title
                Text("Welcome Back")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                    .frame(height: 20)
                
                // Phone Auth Button
                Button(action: {
                    showPhoneAuth = true
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                        Text("Continue with Phone")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                
                // Or Divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("or")
                        .foregroundColor(.gray)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                
                // Apple Sign In Button
                SignInWithAppleButton { request in
                    viewModel.handleAppleSignInRequest(request)
                } onCompletion: { result in
                    Task {
                        if await viewModel.handleAppleSignInCompletion(result) {
                            isPresented = false
                        }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(16)
                .padding(.horizontal, 32)
                
                // Google Sign In Button
                Button(action: {
                    Task {
                        if await viewModel.signInWithGoogle() {
                            isPresented = false
                        }
                    }
                }) {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 32)
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button(action: {
                        isPresented = false
                        showOnboarding = true
                    }) {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .sheet(isPresented: $showPhoneAuth) {
            PhoneAuthView(isPresented: $showPhoneAuth)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct PhoneAuthView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AuthViewModel()
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var showVerificationField = false
    @State private var verificationID: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !showVerificationField {
                    // Phone Number Input
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Send Code") {
                        Task {
                            if let id = await viewModel.startPhoneVerification(phoneNumber: phoneNumber) {
                                verificationID = id
                                showVerificationField = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    // Verification Code Input
                    TextField("Verification Code", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Verify") {
                        Task {
                            if await viewModel.verifyCode(verificationCode, verificationID: verificationID ?? "") {
                                isPresented = false
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Phone Verification")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
        }
    }
}

#Preview {
    LoginView(isPresented: .constant(true), showOnboarding: .constant(false))
} 