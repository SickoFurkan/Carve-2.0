import Foundation

public enum Gender: String, CaseIterable, Codable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"
    
    public var id: String { rawValue }
} 