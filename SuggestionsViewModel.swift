import SwiftUI
import FirebaseFirestore

@MainActor
class SuggestionsViewModel: ObservableObject {
    @Published var suggestions: [Suggestion] = []
    private let firebaseService = FirebaseService.shared
    private let db = Firestore.firestore()
    
    func loadSuggestions() {
        Task {
            do {
                let snapshot = try await db.collection("suggestions")
                    .order(by: "upvotes", descending: true)
                    .getDocuments()
                
                let loadedSuggestions = snapshot.documents.compactMap { document in
                    try? document.data(as: Suggestion.self)
                }
                
                await MainActor.run {
                    self.suggestions = loadedSuggestions
                }
            } catch {
                print("Error loading suggestions: \(error)")
            }
        }
    }
    
    func addSuggestion(title: String, description: String) {
        Task {
            do {
                guard let currentUser = firebaseService.user else {
                    print("Error: Not logged in")
                    return
                }
                
                guard let profile = try await firebaseService.getUserProfile() else {
                    print("Error: Could not load profile")
                    return
                }
                
                let suggestion = Suggestion(
                    userId: currentUser.id,
                    username: profile.username,
                    title: title,
                    description: description
                )
                
                try await db.collection("suggestions").document(suggestion.id).setData(from: suggestion)
                await loadSuggestions()
            } catch {
                print("Error adding suggestion: \(error)")
            }
        }
    }
    
    func toggleUpvote(for suggestion: Suggestion) {
        Task {
            guard let currentUser = firebaseService.user else { return }
            
            do {
                let docRef = db.collection("suggestions").document(suggestion.id)
                
                if suggestion.upvotedBy.contains(currentUser.id) {
                    try await docRef.updateData([
                        "upvotes": FieldValue.increment(Int64(-1)),
                        "upvotedBy": FieldValue.arrayRemove([currentUser.id])
                    ])
                } else {
                    try await docRef.updateData([
                        "upvotes": FieldValue.increment(Int64(1)),
                        "upvotedBy": FieldValue.arrayUnion([currentUser.id])
                    ])
                }
                
                await loadSuggestions()
            } catch {
                print("Error toggling upvote: \(error)")
            }
        }
    }
    
    func hasUpvoted(_ suggestion: Suggestion) -> Bool {
        guard let currentUser = firebaseService.user else { return false }
        return suggestion.upvotedBy.contains(currentUser.id)
    }
} 