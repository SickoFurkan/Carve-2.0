import Foundation

public enum BMICategory: Codable {
    case underweight
    case normal
    case overweight
    case obese
    
    public static func category(for bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }
    
    public var description: String {
        switch self {
        case .underweight:
            return "Underweight - Consider consulting a healthcare professional"
        case .normal:
            return "Normal weight - Keep up the good work!"
        case .overweight:
            return "Overweight - Consider lifestyle changes"
        case .obese:
            return "Obese - Please consult a healthcare professional"
        }
    }
} 