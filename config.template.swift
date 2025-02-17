import Foundation

// TEMPLATE FILE - Copy this to Config.swift and fill in your actual values
public struct Config {
    // OpenAI API Key
    public static var openAIApiKey: String = "YOUR-OPENAI-API-KEY"
    
    // Firebase App Check Debug Token
    public static let appCheckDebugToken = "YOUR-DEBUG-TOKEN"
    
    // Google Sign In Client ID
    public static let googleClientId = "YOUR-GOOGLE-CLIENT-ID"
    
    public static func configure(openAIApiKey: String) {
        self.openAIApiKey = openAIApiKey
    }
} 