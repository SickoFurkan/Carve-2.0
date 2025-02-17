import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import Firebase
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isAnalyzing = false
    @Published var analyzedFoodName = ""
    
    private let firebaseService: FirebaseService
    private var currentNonce: String?
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
        FirebaseConfiguration.configure()
    }
    
    // MARK: - Phone Authentication
    func startPhoneVerification(phoneNumber: String) async -> String? {
        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func verifyCode(_ code: String, verificationID: String) async -> Bool {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        do {
            let result = try await Auth.auth().signIn(with: credential)
            print("User signed in with phone: \(result.user.uid)")
            return true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Apple Sign In Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Apple Sign In
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async -> Bool {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showError = true
                errorMessage = "Invalid credentials"
                return false
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                showError = true
                errorMessage = "Invalid token"
                return false
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                showError = true
                errorMessage = "Unable to serialize token"
                return false
            }
            
            guard let nonce = currentNonce else {
                showError = true
                errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                return false
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            do {
                let result = try await Auth.auth().signIn(with: credential)
                print("User signed in with Apple: \(result.user.uid)")
                return true
            } catch {
                showError = true
                errorMessage = error.localizedDescription
                return false
            }
            
        case .failure(let error):
            showError = true
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showError = true
            errorMessage = "No client ID found"
            return false
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            showError = true
            errorMessage = "No root view controller found"
            return false
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                showError = true
                errorMessage = "No ID token found"
                return false
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            print("User signed in with Google: \(authResult.user.uid)")
            return true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            throw error
        }
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
} 