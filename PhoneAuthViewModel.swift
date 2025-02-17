import Foundation
import FirebaseAuth
import UIKit

@MainActor
class PhoneAuthViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var verificationID: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    private var authUIDelegate: PhoneAuthUIDelegate?
    
    init() {
        self.authUIDelegate = PhoneAuthUIDelegate()
        setupAuthUIDelegate()
    }
    
    private func setupAuthUIDelegate() {
        authUIDelegate?.onError = { [weak self] error in
            Task { @MainActor in
                self?.showError = true
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func sendVerificationCode() async {
        do {
            let formattedNumber = "+31\(phoneNumber)"
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil)
            await MainActor.run {
                self.verificationID = verificationID
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func verifyCode() async {
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: verificationCode
            )
            
            try await Auth.auth().signIn(with: credential)
            await MainActor.run {
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

// MARK: - PhoneAuthUIDelegate
class PhoneAuthUIDelegate: NSObject {
    var onError: ((Error) -> Void)?
    
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}

extension PhoneAuthUIDelegate: AuthUIDelegate {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        Task { @MainActor in
            if let topVC = self.topViewController() {
                viewControllerToPresent.modalPresentationStyle = .fullScreen
                topVC.present(viewControllerToPresent, animated: flag, completion: completion)
            } else {
                self.onError?(NSError(domain: "PhoneAuthError",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Could not present reCAPTCHA verification"]))
            }
        }
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        Task { @MainActor in
            if let topVC = self.topViewController() {
                topVC.dismiss(animated: flag, completion: completion)
            }
        }
    }
} 
