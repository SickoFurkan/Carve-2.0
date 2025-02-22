import SwiftUI
import FirebaseCore

@main
struct CarveApp: App {
    @StateObject private var firebaseService = FirebaseService.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(firebaseService)
        }
    }
} 