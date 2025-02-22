import SwiftUI

struct WorkoutSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var selectedMuscleGroups = Set<MuscleGroup>()
    @State private var workoutName = ""
    @State private var workoutDuration = 60.0
    @State private var showingAlert = false
    @ObservedObject private var workoutStore = WorkoutStore.shared
    
    private let muscleGroups = MuscleGroup.allCases
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Workout Name
                    TextField("Workout Name", text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Duration Slider
                    VStack(alignment: .leading) {
                        Text("Duration: \(Int(workoutDuration)) minutes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Slider(value: $workoutDuration, in: 15...180, step: 5)
                    }
                    .padding(.horizontal)
                    
                    // Muscle Groups Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(muscleGroups) { muscleGroup in
                            MuscleGroupButton(
                                name: muscleGroup.name,
                                icon: muscleGroup.iconName,
                                color: muscleGroup.displayColor,
                                isSelected: selectedMuscleGroups.contains(muscleGroup),
                                onTap: {
                                    if selectedMuscleGroups.contains(muscleGroup) {
                                        selectedMuscleGroups.remove(muscleGroup)
                                    } else {
                                        selectedMuscleGroups.insert(muscleGroup)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if workoutName.isEmpty {
                            showingAlert = true
                        } else {
                            saveWorkout()
                            dismiss()
                        }
                    }
                    .disabled(selectedMuscleGroups.isEmpty)
                }
            }
            .alert("Missing Information", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a workout name")
            }
        }
    }
    
    private func saveWorkout() {
        let workout = Workout(
            name: workoutName,
            duration: Int(workoutDuration),
            muscleGroups: Array(selectedMuscleGroups),
            date: selectedDate
        )
        workoutStore.addWorkout(workout)
    }
} 