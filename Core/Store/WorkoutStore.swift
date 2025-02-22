import SwiftUI

public class WorkoutStore: ObservableObject {
    public static let shared = WorkoutStore()
    
    @Published public private(set) var workouts: [Workout] = []
    private let userDefaults = UserDefaults.standard
    private let storageKey = "workoutHistory"
    
    public init() {
        loadWorkouts()
    }
    
    public func addWorkout(_ workout: Workout) {
        DispatchQueue.main.async {
            self.workouts.append(workout)
            self.saveWorkouts()
        }
    }
    
    public func removeWorkout(_ workout: Workout) {
        DispatchQueue.main.async {
            self.workouts.removeAll { $0.id == workout.id }
            self.saveWorkouts()
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
            .sorted { $0.date > $1.date }
    }
    
    public func getTodaysWorkouts() -> [Workout] {
        return getWorkouts(for: Date())
    }
    
    public func getWorkoutStats(for date: Date) -> (sets: Int, duration: Int, exercises: Int) {
        let dailyWorkouts = getWorkouts(for: date)
        let totalDuration = dailyWorkouts.reduce(0) { $0 + $1.duration }
        let totalExercises = dailyWorkouts.count
        let totalSets = dailyWorkouts.count * 3 // Assuming average 3 sets per workout
        
        return (sets: totalSets, duration: totalDuration, exercises: totalExercises)
    }
    
    // MARK: - Private Methods
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
} 