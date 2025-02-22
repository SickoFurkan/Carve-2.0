import SwiftUI

public struct MuscleGroupButton: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    public init(
        name: String,
        icon: String,
        color: Color,
        isSelected: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    private var muscleGroup: MuscleGroup {
        switch name {
        case "Chest": return .chest
        case "Back": return .back
        case "Legs": return .legs
        case "Shoulders": return .shoulders
        case "Arms": return .biceps // Note: This is simplified, could be either biceps or triceps
        case "Core": return .core
        case "Cardio": return .cardio
        default: return .core
        }
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(name)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(isSelected ? .white : color)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
} 