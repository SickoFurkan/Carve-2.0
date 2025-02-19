import SwiftUI

struct AddActionSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    let onWorkoutTap: () -> Void
    let onCameraTap: () -> Void
    let onLibraryTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Action sheet content
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray)
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                
                HStack(spacing: 20) {
                    // Left section - Workout
                    VStack {
                        Button(action: onWorkoutTap) {
                            VStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 24))
                                Text("Add Workout")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right section - Food
                    VStack(spacing: 12) {
                        Button(action: onCameraTap) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Camera")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: onLibraryTap) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24))
                                Text("Library")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .transition(.move(edge: .bottom))
    }
} 