import Foundation
import FirebaseFirestore

struct Suggestion: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let title: String
    let description: String
    let createdAt: Date
    var upvotes: Int
    var upvotedBy: [String]  // Array of user IDs who upvoted
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         title: String,
         description: String,
         createdAt: Date = Date(),
         upvotes: Int = 0,
         upvotedBy: [String] = []) {
        self.id = id
        self.userId = userId
        self.username = username
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.upvotedBy = upvotedBy
    }
} 