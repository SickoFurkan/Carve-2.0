import SwiftUI

public enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    
    public var id: String { rawValue }
    
    public var name: String { rawValue }
    
    public var displayColor: Color {
        switch self {
        case .chest:
            return .red
        case .back:
            return .blue
        case .shoulders:
            return .orange
        case .biceps:
            return .green
        case .triceps:
            return .purple
        case .legs:
            return .pink
        case .core:
            return .yellow
        case .cardio:
            return .mint
        }
    }
    
    public var iconName: String {
        switch self {
        case .chest:
            return "figure.arms.open"
        case .back:
            return "figure.walk"
        case .shoulders:
            return "figure.boxing"
        case .biceps:
            return "figure.strengthtraining.traditional"
        case .triceps:
            return "figure.strengthtraining.functional"
        case .legs:
            return "figure.run"
        case .core:
            return "figure.core.training"
        case .cardio:
            return "heart.fill"
        }
    }
} 