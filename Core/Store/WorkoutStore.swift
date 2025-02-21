import SwiftUI

public class WorkoutStore: ObservableObject {
    public static let shared = WorkoutStore()
    
    @Published public private(set) var workouts: [Workout] = []
    
    public init() {}
    
    public func addWorkout(_ workout: Workout) {
        DispatchQueue.main.async {
            self.workouts.append(workout)
        }
    }
    
    public func getMuscleGroups(for date: Date) -> [MuscleGroup] {
        let calendar = Calendar.current
        return workouts
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .flatMap { $0.muscleGroups }
    }
    
    public func getWorkouts(for date: Date) -> [Workout] {
        let calendar = Calendar.current
        return workouts
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
} 