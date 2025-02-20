import SwiftUI

struct ProfileErrorView: View {
    let error: String
    let firebaseService: FirebaseService
    @Binding var showingOnboarding: Bool
    let onRetry: () async -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("Kon profielgegevens niet laden")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                firebaseService.debugCheckUserStatus()
            }) {
                Label("Check Firebase Status", systemImage: "magnifyingglass")
                    .foregroundColor(.blue)
            }
            .padding(.top)
            
            Button(action: {
                showingOnboarding = true
            }) {
                Label("Profiel aanmaken", systemImage: "person.badge.plus")
                    .foregroundColor(.green)
            }
            .padding(.top)
            
            Button("Opnieuw proberen") {
                Task {
                    await onRetry()
                }
            }
            .padding(.top)
        }
        .padding()
    }
} 