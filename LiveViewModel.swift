import SwiftUI
import FirebaseFirestore

@MainActor
class LiveViewModel: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var friendRequests: [UserProfile] = []
    @Published var searchResults: [UserProfile] = []
    
    private let firebaseService = FirebaseService.shared
    private let db = Firestore.firestore()
    
    func loadFriends() async {
        do {
            guard let currentUserId = firebaseService.user?.id else { return }
            
            // Fetch friend IDs from the friends collection
            let friendsSnapshot = try await db.collection("friends")
                .document(currentUserId)
                .collection("user_friends")
                .getDocuments()
            
            // Get friend profiles
            var loadedFriends: [UserProfile] = []
            for doc in friendsSnapshot.documents {
                if let friendId = doc.data()["userId"] as? String,
                   let friendProfile = try await firebaseService.getUserProfileById(friendId) {
                    loadedFriends.append(friendProfile)
                }
            }
            
            self.friends = loadedFriends
            
            // Load friend requests
            let requestsSnapshot = try await db.collection("friend_requests")
                .document(currentUserId)
                .collection("pending")
                .getDocuments()
            
            var loadedRequests: [UserProfile] = []
            for doc in requestsSnapshot.documents {
                if let requesterId = doc.data()["fromUserId"] as? String,
                   let requesterProfile = try await firebaseService.getUserProfileById(requesterId) {
                    loadedRequests.append(requesterProfile)
                }
            }
            
            self.friendRequests = loadedRequests
        } catch {
            print("Error loading friends: \(error)")
        }
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            do {
                let snapshot = try await db.collection("users")
                    .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
                    .whereField("username", isLessThan: query.lowercased() + "z")
                    .limit(to: 10)
                    .getDocuments()
                
                var results: [UserProfile] = []
                for doc in snapshot.documents {
                    if let profile = try? Firestore.Decoder().decode(UserProfile.self, from: doc.data()) {
                        // Don't show current user and existing friends in search results
                        if profile.id != firebaseService.user?.id && !friends.contains(where: { $0.id == profile.id }) {
                            results.append(profile)
                        }
                    }
                }
                
                await MainActor.run {
                    self.searchResults = results
                }
            } catch {
                print("Error searching users: \(error)")
            }
        }
    }
    
    func sendFriendRequest(to user: UserProfile) {
        Task {
            do {
                guard let currentUserId = firebaseService.user?.id else { return }
                
                // Add friend request to recipient's pending requests
                try await db.collection("friend_requests")
                    .document(user.id)
                    .collection("pending")
                    .document(currentUserId)
                    .setData([
                        "fromUserId": currentUserId,
                        "timestamp": FieldValue.serverTimestamp()
                    ])
                
                // Remove from search results
                await MainActor.run {
                    searchResults.removeAll(where: { $0.id == user.id })
                }
            } catch {
                print("Error sending friend request: \(error)")
            }
        }
    }
    
    func acceptFriendRequest(from user: UserProfile) async {
        do {
            guard let currentUserId = firebaseService.user?.id else { return }
            
            // Add to both users' friend lists
            try await db.collection("friends")
                .document(currentUserId)
                .collection("user_friends")
                .document(user.id)
                .setData([
                    "userId": user.id,
                    "timestamp": FieldValue.serverTimestamp()
                ])
            
            try await db.collection("friends")
                .document(user.id)
                .collection("user_friends")
                .document(currentUserId)
                .setData([
                    "userId": currentUserId,
                    "timestamp": FieldValue.serverTimestamp()
                ])
            
            // Remove the friend request
            try await db.collection("friend_requests")
                .document(currentUserId)
                .collection("pending")
                .document(user.id)
                .delete()
            
            // Update local state
            await MainActor.run {
                friendRequests.removeAll(where: { $0.id == user.id })
                friends.append(user)
            }
        } catch {
            print("Error accepting friend request: \(error)")
        }
    }
    
    func declineFriendRequest(from user: UserProfile) async {
        do {
            guard let currentUserId = firebaseService.user?.id else { return }
            
            // Remove the friend request
            try await db.collection("friend_requests")
                .document(currentUserId)
                .collection("pending")
                .document(user.id)
                .delete()
            
            // Update local state
            await MainActor.run {
                friendRequests.removeAll(where: { $0.id == user.id })
            }
        } catch {
            print("Error declining friend request: \(error)")
        }
    }
    
    func removeFriend(_ friend: UserProfile) async {
        do {
            guard let currentUserId = firebaseService.user?.id else { return }
            
            // Remove from both users' friend lists
            try await db.collection("friends")
                .document(currentUserId)
                .collection("user_friends")
                .document(friend.id)
                .delete()
            
            try await db.collection("friends")
                .document(friend.id)
                .collection("user_friends")
                .document(currentUserId)
                .delete()
            
            // Update local state
            await MainActor.run {
                friends.removeAll(where: { $0.id == friend.id })
            }
        } catch {
            print("Error removing friend: \(error)")
        }
    }
} 