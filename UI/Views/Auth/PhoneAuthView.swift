import SwiftUI
import FirebaseAuth

struct PhoneAuthView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
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
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Phone Verification")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    PhoneAuthView(isPresented: .constant(true))
} 