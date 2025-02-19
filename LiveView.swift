import SwiftUI
import Foundation

struct LiveView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Active Users Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Now")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<5) { _ in
                                ActiveUserView()
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .cardStyle()
            
            // Live Workouts Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Live Workouts")
                        .font(.headline)
                    
                    ForEach(0..<3) { index in
                        LiveWorkoutRow()
                        if index < 2 {
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .cardStyle()
            
            // Recent Activity Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                    
                    ForEach(0..<4) { index in
                        ActivityRow()
                        if index < 3 {
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .cardStyle()
        }
        .standardPageLayout()
    }
}

struct ActiveUserView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("John D.")
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct LiveWorkoutRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Upper Body Workout")
                    .font(.subheadline)
                Text("Sarah K. • 3 others")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Join")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mike completed Upper Body workout")
                    .font(.subheadline)
                Text("2 minutes ago")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LiveView()
} 