import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileManager: ObservableObject {
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var isLoading = false
    
    private var isFetching = false
    private let db = Firestore.firestore()
    
    static let shared = ProfileManager()
    
    private init() {}
    
    func fetchUserProfile(forceRefresh: Bool = false) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }
        
        // If we already have data and no refresh is requested, return cached data
        if !forceRefresh, let profile = userProfile {
            print("📱 Returning cached profile data")
            return
        }
        
        // If a fetch is already in progress, wait for it to complete
        if isFetching {
            print("🔄 Profile fetch already in progress")
            return
        }
        
        print("🔍 Fetching user profile from Firestore")
        isFetching = true
        isLoading = true
        
        defer {
            isFetching = false
            isLoading = false
        }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard let data = document.data() else {
                throw NSError(domain: "ProfileManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No profile data found"])
            }
            
            guard let profile = UserProfile(documentData: data, documentId: document.documentID) else {
                throw NSError(domain: "ProfileManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse profile data"])
            }
            
            self.userProfile = profile
            print("✅ Successfully fetched and cached user profile")
            
        } catch {
            print("❌ Error fetching user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func clearCache() {
        userProfile = nil
        print("🗑️ Cleared profile cache")
    }
    
    func refreshProfile() async throws {
        try await fetchUserProfile(forceRefresh: true)
    }
} 
