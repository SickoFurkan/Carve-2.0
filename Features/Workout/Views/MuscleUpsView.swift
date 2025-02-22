import SwiftUI
import Charts

struct MuscleUpsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var showingProfile = false
    @State private var selectedSection = 0
    @State private var showingNewWorkout = false
    @State private var activeWorkout: Workout?
    @State private var showingChallenges = false
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 16) {
            // Workout Summary Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Workout")
                        .font(.headline)
                    
                    let stats = workoutStore.getWorkoutStats(for: selectedDate)
                    HStack(spacing: 20) {
                        WorkoutStatView(
                            value: "\(stats.sets)",
                            label: "Sets",
                            icon: "figure.strengthtraining.traditional",
                            unit: ""
                        )
                        
                        WorkoutStatView(
                            value: "\(stats.duration)",
                            label: "Minutes",
                            icon: "clock.fill",
                            unit: ""
                        )
                        
                        WorkoutStatView(
                            value: "\(stats.exercises)",
                            label: "Exercises",
                            icon: "dumbbell.fill",
                            unit: ""
                        )
                    }
                }
                .padding()
            }
            
            // Recent Workouts Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Workouts")
                        .font(.headline)
                    
                    let workouts = workoutStore.getWorkouts(for: selectedDate)
                    if workouts.isEmpty {
                        Text("No workouts logged for today")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        ForEach(workouts) { workout in
                            WorkoutRow(workout: workout)
                            if workout.id != workouts.last?.id {
                                Divider()
                            }
                        }
                    }
                    
                    Button(action: {
                        showingNewWorkout = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Workout")
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
        .standardPageLayout()
        .sheet(isPresented: $showingNewWorkout) {
            WorkoutSelectorView(selectedDate: $selectedDate)
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                Text(workout.muscleGroups.map { $0.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(workout.duration) min")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct WorkoutStatView: View {
    let value: String
    let label: String
    let icon: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            Text(value + unit)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// Sample Data Models
struct ProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct PR: Identifiable {
    let id = UUID()
    let exercise: String
    let weight: Int
    let reps: Int
    let date: String
}

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let progress: Int
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Int
}

// Sample Data
let sampleProgressData: [ProgressData] = [
    ProgressData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, weight: 80),
    ProgressData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, weight: 82.5),
    ProgressData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, weight: 85),
    ProgressData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, weight: 85),
    ProgressData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, weight: 87.5),
    ProgressData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, weight: 90)
]

let samplePRs: [PR] = [
    PR(exercise: "Bench Press", weight: 100, reps: 5, date: "Vandaag"),
    PR(exercise: "Squat", weight: 140, reps: 3, date: "Gisteren"),
    PR(exercise: "Deadlift", weight: 180, reps: 1, date: "3 dagen geleden")
]

let sampleChallenges: [Challenge] = [
    Challenge(title: "50 Push-ups per dag", progress: 80),
    Challenge(title: "100 Pull-ups per week", progress: 65),
    Challenge(title: "20 Muscle-ups bereiken", progress: 45)
]

// Placeholder Views
struct NewWorkoutView: View {
    var body: some View {
        Text("Nieuwe Workout")
    }
}

struct ChallengesView: View {
    var body: some View {
        Text("Challenges")
    }
}

#Preview {
    MuscleUpsView(selectedDate: .constant(Date()))
        .environmentObject(WorkoutStore())
} 
