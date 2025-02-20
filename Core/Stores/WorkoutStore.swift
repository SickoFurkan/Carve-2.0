import Foundation
import SwiftUI

public enum MuscleGroup: String, Codable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core
    case cardio
    
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .legs: return .purple
        case .shoulders: return .orange
        case .arms: return .green
        case .core: return .yellow
        case .cardio: return .pink
        }
    }
}

public struct WorkoutEntry: Codable, Identifiable {
    public let id: UUID
    public let date: Date
    public let muscleGroups: [MuscleGroup]
    public let name: String
    public let duration: TimeInterval
    public let exercises: [String]
    
    public init(
        id: UUID = UUID(),
        date: Date,
        muscleGroups: [MuscleGroup],
        name: String,
        duration: TimeInterval,
        exercises: [String]
    ) {
        self.id = id
        self.date = date
        self.muscleGroups = muscleGroups
        self.name = name
        self.duration = duration
        self.exercises = exercises
    }
}

@MainActor
public class WorkoutStore: ObservableObject {
    @Published public var workouts: [WorkoutEntry] = []
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "workouts"
    
    public init() {
        loadWorkouts()
    }
    
    public func addWorkout(
        muscleGroups: [MuscleGroup],
        name: String,
        duration: TimeInterval,
        exercises: [String],
        for date: Date
    ) {
        let workout = WorkoutEntry(
            date: date,
            muscleGroups: muscleGroups,
            name: name,
            duration: duration,
            exercises: exercises
        )
        
        // Find existing workout for the date
        if let index = workouts.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            // Override the existing workout with the new one
            workouts[index] = workout
        } else {
            workouts.append(workout)
        }
        saveWorkouts()
    }
    
    public func getMuscleGroups(for date: Date) -> [MuscleGroup] {
        if let workout = workouts.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return workout.muscleGroups
        }
        return []
    }
    
    public func getWorkoutColor(for date: Date) -> Color {
        let muscleGroups = getMuscleGroups(for: date)
        if muscleGroups.isEmpty {
            return .gray.opacity(0.3)
        } else if muscleGroups.count == 1 {
            return muscleGroups[0].color
        } else {
            // For multiple muscle groups, create a gradient effect
            // You can implement a more sophisticated color blending here
            return .blue.opacity(0.6)
        }
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WorkoutEntry].self, from: data) {
            workouts = decoded
        }
    }
} 