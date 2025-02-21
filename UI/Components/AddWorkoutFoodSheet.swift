import SwiftUI

struct AddWorkoutFoodSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var nutritionStore: NutritionStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedTab = 0
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Tab Selector
                Picker("Select Type", selection: $selectedTab) {
                    Text("Workout").tag(0)
                    Text("Food").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                if selectedTab == 0 {
                    // Workout Section
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]) {
                            MuscleGroupButton(
                                name: "Chest",
                                icon: "figure.strengthtraining.traditional",
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
                            
                            MuscleGroupButton(
                                name: "Cardio",
                                icon: "heart.fill",
                                color: .pink,
                                onTap: { addWorkout(.cardio) }
                            )
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Food Section
                    VStack(spacing: 20) {
                        TextField("A banana and a small milkshake", text: .constant(""))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                Text("Take Photo")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            // Handle library selection
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 20))
                                Text("Choose from Library")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .navigationTitle(selectedTab == 0 ? "Add Workout" : "Add Food")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(nutritionStore: nutritionStore)
                .environmentObject(cameraManager)
        }
    }
    
    private func addWorkout(_ muscleGroup: MuscleGroup) {
        let workout = Workout(
            name: "\(muscleGroup.name) Workout",
            duration: 0,
            muscleGroups: [muscleGroup],
            date: Date()
        )
        workoutStore.addWorkout(workout)
        isPresented = false
    }
} 