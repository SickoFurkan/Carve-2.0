import SwiftUI
import Charts

struct MuscleUpsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showingProfile = false
    @State private var selectedSection = 0
    @State private var showingNewWorkout = false
    @State private var activeWorkout: Workout?
    @State private var showingChallenges = false
    @Binding var selectedDate: Date
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats Card
                CardView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Deze Week")
                                .font(.headline)
                            Spacer()
                            Menu {
                                Button("Deze Week") { }
                                Button("Deze Maand") { }
                                Button("Dit Jaar") { }
                            } label: {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            StatBlock(value: "4", label: "Workouts", icon: "figure.strengthtraining.traditional")
                            StatBlock(value: "12,450", label: "KG Totaal", icon: "dumbbell.fill")
                            StatBlock(value: "3", label: "PR's", icon: "star.fill")
                        }
                    }
                }
                
                // Active Workout or Start Workout Button
                if let workout = activeWorkout {
                    ActiveWorkoutCard(workout: workout)
                } else {
                    CardView {
                        Button(action: { showingNewWorkout = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Start Nieuwe Training")
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
                
                // Progress Charts
                CardView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progressie")
                            .font(.headline)
                        
                        Chart {
                            ForEach(sampleProgressData) { data in
                                LineMark(
                                    x: .value("Datum", data.date),
                                    y: .value("Gewicht", data.weight)
                                )
                                .foregroundStyle(.blue)
                                
                                PointMark(
                                    x: .value("Datum", data.date),
                                    y: .value("Gewicht", data.weight)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(height: 200)
                        
                        Text("Bench Press Progressie")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Recent PRs
                CardView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recente PR's 💪")
                            .font(.headline)
                        
                        ForEach(samplePRs) { pr in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(pr.exercise)
                                        .font(.subheadline)
                                    Text("\(pr.weight)kg × \(pr.reps)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(pr.date)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            if pr.id != samplePRs.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                
                // Challenges
                CardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Actieve Challenges")
                                .font(.headline)
                                Spacer()
                                Button(action: { showingChallenges = true }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                        }
                        
                        ForEach(sampleChallenges) { challenge in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(challenge.title)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(challenge.progress)%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                ProgressView(value: Double(challenge.progress) / 100)
                                    .tint(.blue)
                            }
                            if challenge.id != sampleChallenges.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .edgesIgnoringSafeArea(.all)
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
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: date).uppercased()
    }
}

struct StatBlock: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActiveWorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(workout.name)
                        .font(.headline)
                    Spacer()
                    Text(workout.duration)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                ForEach(workout.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.subheadline)
                        Text("\(exercise.sets) sets × \(exercise.reps) reps @ \(exercise.weight)kg")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {}) {
                    Text("Voltooi Workout")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
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

struct Workout {
    let name: String
    let duration: String
    let exercises: [Exercise]
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
} 