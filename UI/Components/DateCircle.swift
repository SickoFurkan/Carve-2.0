import SwiftUI

struct DateCircle: View {
    let date: Date
    let isSelected: Bool
    let pageType: NavigationPageType
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var isAnimating = false
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var dateTextColor: Color {
        if muscleGroupColor != .clear {
            return .white
        } else if isSelected {
            return .primary
        } else if isToday {
            return .primary
        } else {
            return colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.7)
        }
    }
    
    private var calorieRingColor: Color {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000 // This should come from user's profile
        
        if calories == 0 {
            return .gray.opacity(0.3)
        } else if calories < Int(Double(goalCalories) * 0.5) {
            return .blue.opacity(0.3)
        } else if calories < Int(Double(goalCalories) * 0.8) {
            return .blue.opacity(0.6)
        } else if calories <= goalCalories {
            return .blue
        } else {
            return .red
        }
    }
    
    private var muscleGroupColor: Color {
        let muscleGroups = workoutStore.getMuscleGroups(for: date)
        if muscleGroups.isEmpty {
            return .clear
        } else if muscleGroups.count == 1 {
            return muscleGroups[0].displayColor
        } else {
            return .blue
        }
    }
    
    private var calorieProgress: Double {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000.0 // This should come from user's profile
        return min(Double(calories) / goalCalories, 1.0)
    }
    
    private var hasCalories: Bool {
        nutritionStore.getTotalCaloriesForDate(date) > 0
    }
    
    private var indicatorText: String {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        if calories > 0 {
            return "\(calories)"
        }
        return " " // Empty space to maintain layout
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 2)
                    .frame(width: 36, height: 36)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(calorieRingColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                // Inner Circle with Muscle Group Color
                Circle()
                    .fill(muscleGroupColor)
                    .frame(width: 30, height: 30)
                
                // Date Text
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(dateTextColor)
            }
            
            // Indicator Text with consistent height
            Text(indicatorText)
                .font(.system(size: 10))
                .foregroundColor(hasCalories ? (isSelected ? .primary : .gray) : .clear)
                .frame(height: 12)
                .contentShape(Rectangle())
        }
        .frame(width: 50)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
} 