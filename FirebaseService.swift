import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Firebase
import Foundation

// Custom user type
public struct UserInfo {
    public let id: String
    public let email: String?
}

public class FirebaseService: ObservableObject {
    @Published public var user: UserInfo?
    @Published public var isAuthenticated = false
    @Published public var errorMessage: String?
    
    public static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    @Published var currentUser: UserProfile?
    
    private init() {
        let listenerHandle = FirebaseAuth.Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.user = UserInfo(id: user.uid, email: user.email)
                // Check and create profile if needed
                Task {
                    await self?.createProfileIfNeeded(for: user)
                }
            } else {
                self?.user = nil
            }
            self?.isAuthenticated = user != nil
        }
        // Store the listener handle if you need to remove the listener later
        self.authStateListenerHandle = listenerHandle
    }
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    deinit {
        if let handle = authStateListenerHandle {
            FirebaseAuth.Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication Methods
    
    public func signUp(email: String, password: String) async throws {
        try await FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password)
    }
    
    public func signIn(email: String, password: String) async throws {
        try await FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password)
    }
    
    public func signOut() {
        do {
            try FirebaseAuth.Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - User Profile Methods
    
    public func saveUserProfile(_ profile: UserProfile) async throws {
        let dictionary = profile.firestoreData
        try await db.collection("users").document(profile.id).setData(dictionary)
    }
    
    public func getUserProfile() async throws -> UserProfile? {
        guard let userId = user?.id else {
            print("❌ getUserProfile failed: No user ID available")
            return nil
        }
        
        return try await getUserProfileById(userId)
    }
    
    public func getUserProfileById(_ userId: String) async throws -> UserProfile? {
        do {
            print("📝 Attempting to fetch profile for user: \(userId)")
            let docSnapshot = try await db.collection("users").document(userId).getDocument()
            
            if !docSnapshot.exists {
                print("❌ No profile document exists for user: \(userId)")
                return nil
            }
            
            guard let data = docSnapshot.data() else {
                print("❌ Document exists but has no data for user: \(userId)")
                return nil
            }
            
            print("✅ Successfully fetched profile data: \(data)")
            return UserProfile.from(firestoreData: data)
        } catch {
            print("❌ Error fetching user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func hasCompletedOnboarding() async -> Bool {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return false }
        
        do {
            if let profile = try await getUserProfileById(userId) {
                // Check if the profile has been fully completed
                return !profile.fullName.isEmpty && profile.height > 0 && profile.weight > 0
            }
            return false
        } catch {
            print("❌ Error checking onboarding status: \(error)")
            return false
        }
    }
    
    // MARK: - Food Entry Methods
    
    public func deleteFoodEntry(documentId: String) async throws {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else {
            throw AuthError.userNotAuthenticated
        }
        
        // First verify that this entry belongs to the current user
        let document = try await db.collection("food_entries").document(documentId).getDocument()
        guard let data = document.data(),
              let entryUserId = data["userId"] as? String,
              entryUserId == userId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unauthorized to delete this entry"])
        }
        
        // Delete the document
        try await db.collection("food_entries").document(documentId).delete()
        print("✅ Food entry deleted successfully")
    }
    
    public func saveFoodEntry(_ entry: FoodEntry) async throws {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else {
            throw AuthError.userNotAuthenticated
        }
        
        print("🔄 Preparing to save food entry to Firestore:")
        print("   - Name: \(entry.name)")
        print("   - Description: \(entry.description)")
        
        let data: [String: Any] = [
            "userId": userId,
            "name": entry.name,
            "description": entry.description,
            "amount": entry.amount,
            "calories": entry.calories,
            "protein": entry.protein,
            "carbs": entry.carbs,
            "fat": entry.fat,
            "imageBase64": entry.imageBase64 as Any,
            "timestamp": Timestamp(date: Date())
        ]
        
        try await db.collection("food_entries").document().setData(data)
        print("✅ Food entry saved to Firestore")
    }
    
    public func getFoodEntries(for date: Date = Date()) async throws -> [FoodEntry] {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else {
            throw AuthError.userNotAuthenticated
        }
        
        // Create date range for the selected day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await db.collection("food_entries")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("timestamp", isLessThan: Timestamp(date: endOfDay))
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        print("📥 Loading food entries from Firestore")
        let entries = snapshot.documents.compactMap { document in
            let data = document.data()
            let entry = FoodEntry(
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                amount: data["amount"] as? Int ?? 0,
                calories: data["calories"] as? Int ?? 0,
                protein: data["protein"] as? Int ?? 0,
                carbs: data["carbs"] as? Int ?? 0,
                fat: data["fat"] as? Int ?? 0,
                imageBase64: data["imageBase64"] as? String
            )
            print("   - Loaded entry: \(entry.name) - \(entry.description)")
            return entry
        }
        
        print("✅ Loaded \(entries.count) entries")
        return entries
    }
    
    public func debugCheckUserStatus() {
        if let currentUser = Auth.auth().currentUser {
            print("🔍 Current Firebase User Status:")
            print("   - User ID: \(currentUser.uid)")
            print("   - Email: \(currentUser.email ?? "No email")")
            print("   - Email Verified: \(currentUser.isEmailVerified)")
            print("   - Display Name: \(currentUser.displayName ?? "No display name")")
            print("   - Creation Date: \(currentUser.metadata.creationDate?.description ?? "Unknown")")
            print("   - Last Sign In: \(currentUser.metadata.lastSignInDate?.description ?? "Unknown")")
            
            // Check Firestore document
            Task {
                do {
                    let docSnapshot = try await db.collection("users").document(currentUser.uid).getDocument()
                    if docSnapshot.exists {
                        print("📄 Firestore user document exists:")
                        if let data = docSnapshot.data() {
                            print("   Data: \(data)")
                        } else {
                            print("   Document exists but is empty")
                        }
                    } else {
                        print("❌ No Firestore document exists for this user")
                        print("   Collection: users")
                        print("   Document ID: \(currentUser.uid)")
                    }
                } catch {
                    print("❌ Error checking Firestore: \(error.localizedDescription)")
                }
            }
        } else {
            print("❌ No user is currently signed in")
        }
    }
    
    private func createProfileIfNeeded(for user: FirebaseAuth.User) async {
        do {
            if try await getUserProfileById(user.uid) == nil {
                print("📝 Creating default profile for new user")
                let newProfile = UserProfile(
                    id: user.uid,
                    email: user.email ?? "",
                    username: user.email?.components(separatedBy: "@").first ?? "",
                    fullName: "",
                    birthDate: Date(),
                    gender: .preferNotToSay,
                    height: 175,
                    weight: 75,
                    createdAt: Date()
                )
                try await saveUserProfile(newProfile)
                print("✅ Default profile created successfully")
            }
        } catch {
            print("❌ Error creating default profile: \(error)")
        }
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(UserProfile.self, from: jsonData)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        let data = try JSONEncoder().encode(profile)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("users").document(profile.id).updateData(dictionary)
    }
    
    func deleteUserProfile(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
    }
}

// MARK: - Supporting Models

public enum AuthError: Error {
    case userNotAuthenticated
} 
