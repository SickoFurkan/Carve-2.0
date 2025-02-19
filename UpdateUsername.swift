import FirebaseCore
import FirebaseFirestore
import Firebase

struct UpdateUsername {
    static func main() async throws {
        // Initialize Firebase
        FirebaseApp.configure()
        
        let db = Firestore.firestore()
        let userId = "UXeWXHRpAuYKXgvOS2wcHrti0t42"
        let newUsername = "Goku"
        
        // Update the username
        do {
            try await db.collection("users").document(userId).updateData([
                "username": newUsername
            ])
            print("✅ Username successfully updated to: \(newUsername)")
        } catch {
            print("❌ Error updating username: \(error.localizedDescription)")
        }
        exit(0)
    }
} 