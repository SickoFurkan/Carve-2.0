import Foundation

public struct ValidationMessage: Hashable {
    public let text: String
    public let isValid: Bool
    
    public init(text: String, isValid: Bool) {
        self.text = text
        self.isValid = isValid
    }
} 