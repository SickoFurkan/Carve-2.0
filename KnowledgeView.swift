import SwiftUI

struct KnowledgeView: View {
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Knowledge Base")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    // Placeholder content - You can customize this
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workout Tips")
                                .font(.headline)
                            Text("Learn about proper form and techniques")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .cardStyle()
                    
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition Guide")
                                .font(.headline)
                            Text("Understand macro and micronutrients")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .cardStyle()
                }
                .padding(.vertical)
            }
        }
    }
}

#Preview {
    KnowledgeView()
} 