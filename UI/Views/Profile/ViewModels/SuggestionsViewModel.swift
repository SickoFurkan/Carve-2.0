import SwiftUI
import FirebaseFirestore

// FoodSuggestion model that conforms to Sendable
struct FoodSuggestion: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let nutritionalInfo: [String: Int]
    let upvotes: Int
    let upvotedBy: [String]
    let userId: String
    let username: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         nutritionalInfo: [String: Int],
         upvotes: Int = 0,
         upvotedBy: [String] = [],
         userId: String = "",
         username: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.nutritionalInfo = nutritionalInfo
        self.upvotes = upvotes
        self.upvotedBy = upvotedBy
        self.userId = userId
        self.username = username
        self.createdAt = createdAt
    }
}

struct FoodSuggestionData: Sendable {
    let name: String
    let description: String
    let nutritionalInfo: [String: Int]
}

@MainActor
final class SuggestionsViewModel: ObservableObject, @unchecked Sendable {
    @Published private(set) var suggestions: [FoodSuggestion] = []
    private let chatGPTService: ChatGPTService
    private let firebaseService: FirebaseService
    private let db: Firestore
    
    init(chatGPTService: ChatGPTService = ChatGPTService(), firebaseService: FirebaseService = .shared) {
        self.chatGPTService = chatGPTService
        self.firebaseService = firebaseService
        self.db = Firestore.firestore()
    }
    
    func fetchSuggestions() async throws {
        let snapshot = try await db.collection("suggestions").getDocuments()
        await MainActor.run {
            self.suggestions = snapshot.documents.compactMap { document -> FoodSuggestion? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let nutritionalInfo = data["nutritionalInfo"] as? [String: Int],
                      let upvotes = data["upvotes"] as? Int,
                      let upvotedBy = data["upvotedBy"] as? [String],
                      let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                return FoodSuggestion(
                    id: document.documentID,
                    name: name,
                    description: description,
                    nutritionalInfo: nutritionalInfo,
                    upvotes: upvotes,
                    upvotedBy: upvotedBy,
                    userId: userId,
                    username: username,
                    createdAt: createdAt
                )
            }
        }
    }
    
    func getSuggestions() async throws -> [FoodSuggestion] {
        _ = try await fetchSuggestionData()
        let loadedSuggestions = try await db.collection("suggestions")
            .order(by: "upvotes", descending: true)
            .getDocuments()
            .documents
            .compactMap { document -> FoodSuggestion? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String else {
                    return nil
                }
                
                let nutritionalInfo = (data["nutritionalInfo"] as? [String: Int]) ?? [:]
                let upvotes = (data["upvotes"] as? Int) ?? 0
                let upvotedBy = (data["upvotedBy"] as? [String]) ?? []
                let userId = (data["userId"] as? String) ?? ""
                let username = (data["username"] as? String) ?? ""
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                return FoodSuggestion(
                    id: document.documentID,
                    name: name,
                    description: description,
                    nutritionalInfo: nutritionalInfo,
                    upvotes: upvotes,
                    upvotedBy: upvotedBy,
                    userId: userId,
                    username: username,
                    createdAt: createdAt
                )
            }
        
        await MainActor.run {
            self.suggestions = loadedSuggestions
        }
        
        return loadedSuggestions
    }
    
    private func fetchSuggestionData() async throws -> [FoodSuggestionData] {
        let snapshot = try await db.collection("suggestions")
            .order(by: "upvotes", descending: true)
            .getDocuments()
        
        return try await withThrowingTaskGroup(of: FoodSuggestionData?.self) { group in
            var results: [FoodSuggestionData] = []
            
            for document in snapshot.documents {
                group.addTask {
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String else {
                        return nil
                    }
                    
                    // Handle nutritionalInfo with a default empty dictionary if not present
                    let nutritionalInfo = (data["nutritionalInfo"] as? [String: Int]) ?? [:]
                    
                    return FoodSuggestionData(
                        name: name,
                        description: description,
                        nutritionalInfo: nutritionalInfo
                    )
                }
            }
            
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            
            return results
        }
    }
    
    func analyzeSuggestion(_ suggestion: FoodSuggestion) async throws -> FoodAnalysis? {
        let entry = FoodEntry(
            name: suggestion.name,
            description: suggestion.description,
            amount: 100,  // Default portion size
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0
        )
        
        return try await chatGPTService.analyzeFoodEntry(entry)
    }
    
    func addSuggestion(title: String, description: String) async throws {
        guard let currentUser = firebaseService.user else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }
        
        let profile = try await firebaseService.getUserProfile()
        guard let profile = profile else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load profile"])
        }
        
        let suggestion = FoodSuggestion(
            name: title,
            description: description,
            nutritionalInfo: [:],
            userId: currentUser.id,
            username: profile.username
        )
        
        let data: [String: Any] = [
            "name": suggestion.name,
            "description": suggestion.description,
            "nutritionalInfo": suggestion.nutritionalInfo,
            "upvotes": suggestion.upvotes,
            "upvotedBy": suggestion.upvotedBy,
            "userId": suggestion.userId,
            "username": suggestion.username,
            "createdAt": Timestamp(date: suggestion.createdAt)
        ]
        
        try await db.collection("suggestions").document(suggestion.id).setData(data)
        await loadSuggestions()
    }
    
    func toggleUpvote(for suggestion: FoodSuggestion) async {
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
    
    func hasUpvoted(_ suggestion: FoodSuggestion) -> Bool {
        guard let currentUser = firebaseService.user else { return false }
        return suggestion.upvotedBy.contains(currentUser.id)
    }
    
    private func loadSuggestions() async {
        do {
            let snapshot = try await db.collection("suggestions")
                .order(by: "upvotes", descending: true)
                .getDocuments()
            
            let loadedSuggestions = snapshot.documents.compactMap { document -> FoodSuggestion? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let nutritionalInfo = data["nutritionalInfo"] as? [String: Int],
                      let upvotes = data["upvotes"] as? Int,
                      let upvotedBy = data["upvotedBy"] as? [String],
                      let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                return FoodSuggestion(
                    id: document.documentID,
                    name: name,
                    description: description,
                    nutritionalInfo: nutritionalInfo,
                    upvotes: upvotes,
                    upvotedBy: upvotedBy,
                    userId: userId,
                    username: username,
                    createdAt: createdAt
                )
            }
            
            await MainActor.run {
                self.suggestions = loadedSuggestions
            }
        } catch {
            print("Error loading suggestions: \(error)")
        }
    }
} 
