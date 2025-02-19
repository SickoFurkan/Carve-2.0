import SwiftUI

struct OnboardingUsernameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = OnboardingNameViewModel()
    @State private var username = ""
    @State private var isCheckingAvailability = false
    @State private var showError = false
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Choose Your Username")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This will be your unique identifier in the app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Username Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($isUsernameFocused)
                        .onChange(of: username) { newValue in
                            Task {
                                await viewModel.validateUsername(newValue)
                            }
                        }
                    
                    // Availability indicator
                    if !username.isEmpty {
                        if viewModel.isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if viewModel.isUsernameValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(viewModel.isUsernameValid ? Color.green : (username.isEmpty ? Color.gray : Color.red), lineWidth: 1)
                )
                
                // Validation messages
                if !username.isEmpty {
                    ForEach(viewModel.usernameValidationMessages, id: \.self) { message in
                        HStack {
                            Image(systemName: message.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(message.isValid ? .green : .red)
                            Text(message.text)
                                .font(.caption)
                                .foregroundColor(message.isValid ? .green : .red)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Continue Button
            Button(action: {
                Task {
                    await viewModel.finalizeProfile()
                }
            }) {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isUsernameValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(!viewModel.isUsernameValid || viewModel.isSaving)
            
            Spacer()
        }
        .padding(.top, 50)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            isUsernameFocused = true
        }
    }
}

#Preview {
    OnboardingUsernameView()
} 