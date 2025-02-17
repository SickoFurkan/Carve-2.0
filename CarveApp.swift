//
//  CarveApp.swift
//  Carve
//
//  Created by Furkan Çeliker on 07/02/2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAppCheck
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase first
        FirebaseApp.configure()
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        // Then configure Google Sign-In with the client ID from Firebase
        if let clientID = FirebaseApp.app()?.options.clientID {
            print("📱 Configuring Google Sign In with client ID: \(clientID)")
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        } else {
            print("❌ Failed to get Firebase client ID")
        }
        
        // Configure App Check
        #if DEBUG
        // Set up App Check debug token
        if let debugToken = UserDefaults.standard.string(forKey: "FIRAppCheckDebugToken") {
            print("✅ Using existing App Check debug token: \(debugToken)")
        } else {
            let debugToken = "9F3B7A4B-AD55-4911-83FB-BF762706F891"
            UserDefaults.standard.set(debugToken, forKey: "FIRAppCheckDebugToken")
            print("✅ Stored new App Check debug token: \(debugToken)")
        }
        
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("✅ App Check configured for DEBUG mode")
        #endif
        
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("🔗 Handling URL: \(url.absoluteString)")
        
        // Check if the URL is for Google Sign-In
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
        print("📱 Source application: \(sourceApplication ?? "unknown")")
        
        if sourceApplication == "com.google.ios.googleauth" {
            return GIDSignIn.sharedInstance.handle(url)
        }
        
        return false
    }
    
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification notification: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

@main
struct CarveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(firebaseService)
        }
    }
}
