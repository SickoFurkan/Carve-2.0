import SwiftUI
import AVFoundation
import Photos
import Foundation
import AuthenticationServices

struct Configuration {
    // Replace with your OpenAI API key
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
    
    // App Capabilities
    enum Capabilities {
        static let signInWithApple = true
        static let signInWithGoogle = true
        static let bundleIdentifier = "Celiker.Carve"
        static let teamID = "Furkan Celiker"  // Your Apple Developer Team ID
        static let googleClientID = "192759134127-p1d44h2o45c02rfp6ulpmqfknvqaso7o"
        static let googleURLScheme = "com.googleusercontent.apps.\(googleClientID)"
    }
    
    // Privacy Descriptions
    static let cameraUsageDescription = "We hebben toegang tot je camera nodig om foto's van je voedsel te maken voor analyse."
    static let photoLibraryUsageDescription = "We hebben toegang tot je fotobibliotheek nodig om foto's van je voedsel te selecteren voor analyse."
    
    // App Settings
    static let appName = "Carve"
    static let bundleIdentifier = Capabilities.bundleIdentifier
    
    // Default daily goals
    static let defaultDailyCalories = 2000
    static let defaultProteinGoal = 150 // grams
    static let defaultCarbsGoal = 250 // grams
    static let defaultFatGoal = 65 // grams
    
    // Firebase configuration
    static let firebaseConfig = [
        "apiKey": "YOUR_FIREBASE_API_KEY",
        "authDomain": "YOUR_AUTH_DOMAIN",
        "projectId": "YOUR_PROJECT_ID",
        "storageBucket": "YOUR_STORAGE_BUCKET",
        "messagingSenderId": "YOUR_MESSAGING_SENDER_ID",
        "appId": "YOUR_APP_ID",
        "measurementId": "YOUR_MEASUREMENT_ID"
    ]
}

// Extension to handle permissions
extension Configuration {
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            completion(true)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    static func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized || status == .limited {
            completion(true)
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status == .authorized || status == .limited)
                }
            }
        }
    }
} 