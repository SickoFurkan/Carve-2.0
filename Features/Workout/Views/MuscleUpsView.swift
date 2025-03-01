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
                    
                    HStack(spacing: 20) {
                        WorkoutStatView(
                            value: "0",
                            label: "Sets",
                            icon: "figure.strengthtraining.traditional",
                            unit: ""
                        )
                        
                        WorkoutStatView(
                            value: "0",
                            label: "Minutes",
                            icon: "clock.fill",
                            unit: ""
                        )
                        
                        WorkoutStatView(
                            value: "0",
                            label: "Exercises",
                            icon: "dumbbell.fill",
                            unit: ""
                        )
                    }
                }
            }
            
            // Muscle Groups Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Muscle Groups")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        MuscleGroupButton(
                            name: "Chest",
                            icon: "heart.fill",
                            color: .red,
                            onTap: { addWorkout(.chest) }
                        )
                        MuscleGroupButton(
                            name: "Back",
                            icon: "figure.walk",
                            color: .blue,
                            onTap: { addWorkout(.back) }
                        )
                        MuscleGroupButton(
                            name: "Legs",
                            icon: "figure.walk",
                            color: .purple,
                            onTap: { addWorkout(.legs) }
                        )
                        MuscleGroupButton(
                            name: "Shoulders",
                            icon: "figure.arms.open",
                            color: .orange,
                            onTap: { addWorkout(.shoulders) }
                        )
                        MuscleGroupButton(
                            name: "Arms",
                            icon: "figure.arms.open",
                            color: .green,
                            onTap: { addWorkout(.biceps) }
                        )
                        MuscleGroupButton(
                            name: "Core",
                            icon: "figure.core.training",
                            color: .yellow,
                            onTap: { addWorkout(.core) }
                        )
                    }
                }
            }
            
            // Recent Workouts Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Workouts")
                        .font(.headline)
                    
                    ForEach(0..<3) { _ in
                        WorkoutRow()
                    }
                }
            }
        }
        .standardPageLayout()
        .ignoresSafeArea(.container, edges: [])
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                ProfileView()
                    .navigationBarItems(trailing: Button("Gereed") {
                        showingProfile = false
                    })
            }
        }
        .sheet(isPresented: $showingNewWorkout) {
            NewWorkoutView()
        }
        .sheet(isPresented: $showingChallenges) {
            ChallengesView()
        }
    }
    
    private func addWorkout(_ muscleGroup: MuscleGroup) {
        let workout = Workout(
            name: "\(muscleGroup.name) Workout",
            duration: 0,
            muscleGroups: [muscleGroup],
            date: selectedDate
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            workoutStore.addWorkout(workout)
        }
    }
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: date).uppercased()
    }
}

struct WorkoutRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Upper Body Workout")
                    .font(.subheadline)
                Text("Chest, Shoulders, Arms")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("45 min")
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
