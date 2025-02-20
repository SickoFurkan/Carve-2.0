import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            UserDefaults.standard.synchronize()
        }
    }
    
    static let shared = LanguageManager()
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case dutch = "nl"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .dutch: return "Nederlands"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇬🇧"
            case .dutch: return "🇳🇱"
            }
        }
    }
    
    private init() {
        // Check if user has already set a language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Set default language based on system locale
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = systemLanguage == "nl" ? .dutch : .english
            UserDefaults.standard.set(self.currentLanguage.rawValue, forKey: "AppLanguage")
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        // Post notification for app-wide language change
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
} 