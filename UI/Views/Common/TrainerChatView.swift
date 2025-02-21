import SwiftUI

struct TrainerChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [TrainerMessage] = []
    @ObservedObject var nutritionStore: NutritionStore
    @ObservedObject var workoutStore: WorkoutStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // Message input
                HStack(spacing: 12) {
                    TextField("Ask Goku...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 2)
            }
            .navigationTitle("Your Trainer Goku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Add welcome message
                if messages.isEmpty {
                    messages.append(TrainerMessage(
                        text: "Hey! I'm Goku, your personal trainer. I can help you with nutrition advice and workout plans. What would you like to know?",
                        isFromTrainer: true
                    ))
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Add user message
        messages.append(TrainerMessage(text: trimmedMessage, isFromTrainer: false))
        messageText = ""
        
        // Simulate trainer response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = generateTrainerResponse(to: trimmedMessage)
            messages.append(TrainerMessage(text: response, isFromTrainer: true))
        }
    }
    
    private func generateTrainerResponse(to message: String) -> String {
        // Here you would integrate with ChatGPT or another AI service
        // For now, return a simple response
        let calories = nutritionStore.getTodaysTotalCalories()
        let protein = nutritionStore.getTodaysTotalProtein()
        
        if message.lowercased().contains("calories") {
            return "You've consumed \(calories) calories today. Based on your activity level, I recommend aiming for 2000 calories daily."
        } else if message.lowercased().contains("protein") {
            return "Your protein intake today is \(protein)g. For muscle growth, aim for 1.6-2.2g per kg of body weight."
        } else if message.lowercased().contains("workout") {
            return "I recommend focusing on compound exercises like squats, deadlifts, and bench presses. Would you like a specific workout plan?"
        }
        
        return "I'm here to help! Ask me about your nutrition, workouts, or any fitness-related questions."
    }
}

struct TrainerMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromTrainer: Bool
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: TrainerMessage
    
    var body: some View {
        HStack {
            if message.isFromTrainer {
                // Trainer avatar
                Image(systemName: "figure.strengthtraining")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Message bubble
            Text(message.text)
                .padding(12)
                .background(message.isFromTrainer ? Color(.systemBackground) : Color.blue)
                .foregroundColor(message.isFromTrainer ? .primary : .white)
                .cornerRadius(16)
            
            if !message.isFromTrainer {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
} 