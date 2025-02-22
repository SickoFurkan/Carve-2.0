import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Firebase
import Foundation
import Network

// Custom user type
public struct UserInfo {
    public let id: String
    public let email: String?
}

public class FirebaseService: ObservableObject {
    @Published public var user: UserInfo?
    @Published public var isAuthenticated = false
    @Published public var errorMessage: String?
    @Published public var isOffline = false
    @Published public var isNetworkAvailable = true
    
    public static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let networkMonitor = NetworkMonitor.shared
    private let cache = NSCache<NSString, AnyObject>()
    private var profileFetchTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 3
    
    // Cache keys
    private let userProfileCacheKey = "userProfile"
    private let foodEntriesCacheKey = "foodEntries"
    
    @Published var currentUser: UserProfile?
    
    private init() {
        setupNetworkMonitoring()
        setupFirestoreSettings()
        setupAuthStateListener()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOffline)
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
    
    private func setupFirestoreSettings() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        db.settings = settings
    }
    
    private func setupAuthStateListener() {
        let listenerHandle = FirebaseAuth.Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.user = UserInfo(id: user.uid, email: user.email)
                // Cancel any existing profile fetch task
                self?.profileFetchTask?.cancel()
                // Start new profile fetch task
                self?.profileFetchTask = Task {
                    await self?.createProfileIfNeeded(for: user)
                }
            } else {
                self?.user = nil
                self?.profileFetchTask?.cancel()
                self?.profileFetchTask = nil
            }
            self?.isAuthenticated = user != nil
        }
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
        guard self.isNetworkAvailable else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No network connection available"])
        }
        
        try await retryOperation { [self] in
            try await self.db.collection("users").document(profile.id).setData(profile.firestoreData)
        }
    }
    
    public func getUserProfile() async throws -> UserProfile? {
        // Check network connectivity
        guard self.networkMonitor.isConnected else {
            if let cachedProfile = self.cache.object(forKey: userProfileCacheKey as NSString) as? UserProfile {
                print("📱 Using cached profile data")
                return cachedProfile
            }
            throw NetworkError.noConnection
        }
        
        return try await executeWithRetry { [self] in
            guard let userId = self.user?.id else {
                print("❌ getUserProfile failed: No user ID available")
                return nil
            }
            
            let document = try await self.db.collection("users").document(userId).getDocument()
            guard let data = document.data() else {
                print("❌ getUserProfile failed: No data found")
                return nil
            }
            
            guard let profile = UserProfile(documentData: data, documentId: userId) else {
                print("❌ getUserProfile failed: Could not parse data")
                return nil
            }
            
            // Cache the profile as NSSecureCoding compliant data
            let encoder = JSONEncoder()
            if let encodedProfile = try? encoder.encode(profile) {
                self.cache.setObject(encodedProfile as NSData, forKey: self.userProfileCacheKey as NSString)
            }
            
            return profile
        }
    }
    
    public func getUserProfileById(_ userId: String) async throws -> UserProfile? {
        return try await executeWithRetry { [self] in
            print("📝 Attempting to fetch profile for user: \(userId)")
            let docSnapshot = try await self.db.collection("users").document(userId).getDocument()
            
            if !docSnapshot.exists {
                print("❌ No profile document exists for user: \(userId)")
                return nil
            }
            
            guard let data = docSnapshot.data() else {
                print("❌ Document exists but has no data for user: \(userId)")
                return nil
            }
            
            guard let profile = UserProfile(documentData: data, documentId: userId) else {
                print("❌ Could not parse profile data")
                return nil
            }
            
            print("✅ Successfully fetched profile data")
            return profile
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
        // Check network connectivity
        guard networkMonitor.isConnected else {
            if let cachedEntries = self.cache.object(forKey: "\(self.foodEntriesCacheKey)_\(date)" as NSString) as? [FoodEntry] {
                print("🗂️ Using cached food entries")
                return cachedEntries
            }
            throw NetworkError.noConnection
        }
        
        return try await executeWithRetry {
            guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else {
                throw AuthError.userNotAuthenticated
            }
            
            // Check cache first
            let cacheKey = "\(self.foodEntriesCacheKey)_\(date)" as NSString
            if let cachedEntries = self.cache.object(forKey: cacheKey) as? [FoodEntry] {
                print("🗂️ Using cached food entries")
                return cachedEntries
            }
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let snapshot = try await self.db.collection("food_entries")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("timestamp", isLessThan: Timestamp(date: endOfDay))
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            print("📥 Loading food entries from Firestore")
            let entries = snapshot.documents.compactMap { [self] document -> FoodEntry? in
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
            
            // Cache the entries
            self.cache.setObject(entries as AnyObject, forKey: cacheKey)
            print("💾 Cached \(entries.count) food entries")
            
            return entries
        }
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
                let defaultUsername = user.email?.components(separatedBy: "@").first ?? ""
                let newProfile = UserProfile(
                    id: user.uid,
                    name: user.displayName ?? defaultUsername,
                    email: user.email ?? "",
                    username: defaultUsername,
                    createdAt: Date(),
                    preferences: [:],
                    fullName: user.displayName ?? "",
                    height: 175,
                    weight: 75
                )
                try await saveUserProfile(newProfile)
                print("✅ Default profile created successfully")
            }
        } catch {
            print("❌ Error creating default profile: \(error)")
        }
    }
    
    public func fetchUserProfile(userId: String) async throws -> UserProfile {
        guard isNetworkAvailable else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No network connection available"])
        }
        
        return try await retryOperation { [self] in
            let document = try await self.db.collection("users").document(userId).getDocument()
            
            guard document.exists else {
                throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile document does not exist"])
            }
            
            guard let profile = UserProfile(documentData: document.data() ?? [:], documentId: userId) else {
                print("📝 Debug - Document data: \(document.data() ?? [:])")
                throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse profile data: \(document.data() ?? [:])"])
            }
            
            return profile
        }
    }
    
    public func createDefaultProfile(for userId: String, email: String, name: String) async throws -> UserProfile {
        let now = Date()
        let profile = UserProfile(
            id: userId,
            name: name,
            email: email,
            username: email.components(separatedBy: "@").first ?? "",
            createdAt: now,
            preferences: [:],
            fullName: name,
            height: 0,
            weight: 0,
            dailyCalorieGoal: 2000,
            dailyProteinGoal: 150,
            dailyCarbsGoal: 250,
            dailyFatGoal: 65,
            gender: .preferNotToSay,
            birthDate: now,
            foodEntries: [:]
        )
        
        try await saveUserProfile(profile)
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        let data = try JSONEncoder().encode(profile)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("users").document(profile.id).updateData(dictionary)
    }
    
    func deleteUserProfile(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
    }
    
    private func retryOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            if self.retryCount < self.maxRetries && self.isNetworkAvailable {
                self.retryCount += 1
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(self.retryCount)) * 1_000_000_000))
                return try await self.retryOperation(operation)
            }
            self.retryCount = 0
            throw error
        }
    }
    
    private func executeWithRetry<T>(maxRetries: Int = 3, retryDelay: TimeInterval = 2.0, operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch let error as NSError {
                lastError = error
                
                // Check if it's a network error
                if error.domain == NSURLErrorDomain ||
                   error.domain == "NSPOSIXErrorDomain" ||
                   error.code == 50 { // Network is down
                    
                    if attempt < maxRetries - 1 {
                        print("🔄 Network error, retrying in \(retryDelay) seconds... (Attempt \(attempt + 1)/\(maxRetries))")
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                        continue
                    }
                }
                throw error
            }
        }
        
        throw lastError ?? NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"])
    }
    
    public func loadFriends() async throws -> [UserProfile] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotAuthenticated
        }
        
        print("📝 Loading friends for user: \(currentUserId)")
        
        do {
            // First, get the user's friends document
            let friendsRef = self.db.collection("friends").document(currentUserId)
            let friendsDoc = try await friendsRef.getDocument()
            
            if !friendsDoc.exists {
                print("ℹ️ No friends document exists, creating one")
                try await friendsRef.setData([:])
                return []
            }
            
            // Get all friend IDs from the user_friends subcollection
            let friendsSnapshot = try await friendsRef.collection("user_friends").getDocuments()
            let friendIds = friendsSnapshot.documents.map { $0.documentID }
            
            print("📝 Found \(friendIds.count) friend IDs")
            
            // Fetch friend profiles
            var friends: [UserProfile] = []
            for friendId in friendIds {
                if let friendProfile = try await self.getUserProfileById(friendId) {
                    friends.append(friendProfile)
                    print("✅ Loaded profile for friend: \(friendProfile.name)")
                } else {
                    print("⚠️ Could not load profile for friend ID: \(friendId)")
                }
            }
            
            print("✅ Successfully loaded \(friends.count) friend profiles")
            return friends
            
        } catch let error as NSError {
            if error.domain == FirestoreErrorDomain && error.code == 7 {
                print("❌ Permissions error loading friends - ensuring proper structure")
                // Create the necessary structure with proper permissions
                try await self.db.collection("friends").document(currentUserId).setData([:])
                return []
            }
            print("❌ Error loading friends: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Username Methods
    
    public func isUsernameAvailable(_ username: String) async throws -> Bool {
        let snapshot = try await self.db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        
        return snapshot.documents.isEmpty
    }
    
    public func updateUsername(userId: String, newUsername: String) async throws {
        // First check if username is available
        guard try await isUsernameAvailable(newUsername) else {
            throw NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Username is already taken"]
            )
        }
        
        // Update the username
        try await self.db.collection("users").document(userId).updateData([
            "username": newUsername
        ])
        
        print("✅ Username updated successfully to: \(newUsername)")
    }
    
    public func setUsernameForUser(userId: String, username: String) async throws {
        // First check if username is available (unless it's the same user's current username)
        let currentProfile = try await fetchUserProfile(userId: userId)
        if currentProfile.username != username {
            guard try await isUsernameAvailable(username) else {
                throw NSError(
                    domain: "FirebaseService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Username is already taken"]
                )
            }
        }
        
        // Update the username
        try await self.db.collection("users").document(userId).updateData([
            "username": username
        ])
        
        print("✅ Username set successfully to: \(username)")
    }
}

// MARK: - Supporting Models

public enum AuthError: Error {
    case userNotAuthenticated
}

enum NetworkError: LocalizedError {
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return NSLocalizedString("no_internet_connection", comment: "")
        }
    }
} 
