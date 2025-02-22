import Foundation
import FirebaseFirestore

public enum UserGender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case preferNotToSay = "preferNotToSay"
    case other = "other"
}

public struct UserProfile: Identifiable, Codable {
    public let id: String
    public let name: String
    public let email: String
    public let username: String
    public let createdAt: Date
    public let preferences: [String: String]
    public let fullName: String
    public let height: Double
    public let weight: Double
    public let dailyCalorieGoal: Int
    public let dailyProteinGoal: Int
    public let dailyCarbsGoal: Int
    public let dailyFatGoal: Int
    public let gender: UserGender
    public let birthDate: Date
    public var foodEntries: [String: [FoodEntry]]
    
    public var bmi: Double {
        guard height > 0 else { return 0 }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    public var bmiCategory: BMICategory {
        BMICategory.category(for: bmi)
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case username
        case createdAt
        case preferences
        case fullName
        case height
        case weight
        case dailyCalorieGoal
        case dailyProteinGoal
        case dailyCarbsGoal
        case dailyFatGoal
        case gender
        case birthDate
        case foodEntries
    }
    
    public init(id: String, 
         name: String, 
         email: String,
         username: String,
         createdAt: Date, 
         preferences: [String: String],
         fullName: String = "",
         height: Double = 0,
         weight: Double = 0,
         dailyCalorieGoal: Int = 2000,
         dailyProteinGoal: Int = 150,
         dailyCarbsGoal: Int = 250,
         dailyFatGoal: Int = 65,
         gender: UserGender = .preferNotToSay,
         birthDate: Date = Date(),
         foodEntries: [String: [FoodEntry]] = [:]) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.createdAt = createdAt
        self.preferences = preferences
        self.fullName = fullName
        self.height = height
        self.weight = weight
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.gender = gender
        self.birthDate = birthDate
        self.foodEntries = foodEntries
    }
    
    // Firestore initialization
    public init?(documentData data: [String: Any], documentId: String) {
        print("📝 Attempting to parse profile data:")
        print("   - Document ID: \(documentId)")
        print("   - Data keys present: \(data.keys.joined(separator: ", "))")
        
        // Required fields
        guard let name = data["name"] as? String else {
            print("❌ Missing required field: name")
            return nil
        }
        guard let email = data["email"] as? String else {
            print("❌ Missing required field: email")
            return nil
        }
        guard let createdTimestamp = data["createdAt"] as? Timestamp else {
            print("❌ Missing or invalid createdAt timestamp")
            return nil
        }
        
        // Initialize required fields
        self.id = documentId
        self.name = name
        self.email = email
        self.createdAt = createdTimestamp.dateValue()
        
        // Optional fields with logging
        if let username = data["username"] as? String {
            self.username = username
        } else {
            print("ℹ️ Username not found, using email prefix")
            self.username = email.components(separatedBy: "@").first ?? ""
        }
        
        // Parse remaining fields with detailed logging
        self.preferences = (data["preferences"] as? [String: String]) ?? {
            print("ℹ️ No preferences found, using empty dictionary")
            return [:]
        }()
        
        self.fullName = (data["fullName"] as? String) ?? {
            print("ℹ️ No fullName found, using empty string")
            return ""
        }()
        
        self.height = (data["height"] as? Double) ?? {
            print("ℹ️ No height found, using default 0")
            return 0
        }()
        
        self.weight = (data["weight"] as? Double) ?? {
            print("ℹ️ No weight found, using default 0")
            return 0
        }()
        
        self.dailyCalorieGoal = (data["dailyCalorieGoal"] as? Int) ?? {
            print("ℹ️ No dailyCalorieGoal found, using default 2000")
            return 2000
        }()
        
        self.dailyProteinGoal = (data["dailyProteinGoal"] as? Int) ?? {
            print("ℹ️ No dailyProteinGoal found, using default 150")
            return 150
        }()
        
        self.dailyCarbsGoal = (data["dailyCarbsGoal"] as? Int) ?? {
            print("ℹ️ No dailyCarbsGoal found, using default 250")
            return 250
        }()
        
        self.dailyFatGoal = (data["dailyFatGoal"] as? Int) ?? {
            print("ℹ️ No dailyFatGoal found, using default 65")
            return 65
        }()
        
        if let genderString = data["gender"] as? String,
           let parsedGender = UserGender(rawValue: genderString) {
            self.gender = parsedGender
        } else {
            print("ℹ️ No valid gender found, using preferNotToSay")
            self.gender = .preferNotToSay
        }
        
        if let birthTimestamp = data["birthDate"] as? Timestamp {
            self.birthDate = birthTimestamp.dateValue()
        } else {
            print("ℹ️ No birthDate found, using current date")
            self.birthDate = Date()
        }
        
        self.foodEntries = (data["foodEntries"] as? [String: [FoodEntry]]) ?? {
            print("ℹ️ No foodEntries found, using empty dictionary")
            return [:]
        }()
        
        print("✅ Successfully parsed profile data")
    }
    
    // Convert to Firestore data
    public var firestoreData: [String: Any] {
        return [
            "name": name,
            "email": email,
            "username": username,
            "createdAt": Timestamp(date: createdAt),
            "preferences": preferences,
            "fullName": fullName,
            "height": height,
            "weight": weight,
            "dailyCalorieGoal": dailyCalorieGoal,
            "dailyProteinGoal": dailyProteinGoal,
            "dailyCarbsGoal": dailyCarbsGoal,
            "dailyFatGoal": dailyFatGoal,
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "foodEntries": foodEntries
        ]
    }
    
    // Food Entry Methods
    public func getEntries(for date: String) -> [FoodEntry] {
        return foodEntries[date] ?? []
    }
    
    public func getEntries(for date: Date) -> [FoodEntry] {
        let dateString = DateFormatter.foodEntryDateFormatter.string(from: date)
        return getEntries(for: dateString)
    }
    
    public func addFoodEntry(_ entry: FoodEntry, for date: String) -> UserProfile {
        var updatedEntries = foodEntries
        var entries = updatedEntries[date] ?? []
        entries.append(entry)
        updatedEntries[date] = entries
        
        return UserProfile(
            id: id,
            name: name,
            email: email,
            username: username,
            createdAt: createdAt,
            preferences: preferences,
            fullName: fullName,
            height: height,
            weight: weight,
            dailyCalorieGoal: dailyCalorieGoal,
            dailyProteinGoal: dailyProteinGoal,
            dailyCarbsGoal: dailyCarbsGoal,
            dailyFatGoal: dailyFatGoal,
            gender: gender,
            birthDate: birthDate,
            foodEntries: updatedEntries
        )
    }
    
    // Custom encoding for Firestore Timestamp
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(height, forKey: .height)
        try container.encode(weight, forKey: .weight)
        try container.encode(dailyCalorieGoal, forKey: .dailyCalorieGoal)
        try container.encode(dailyProteinGoal, forKey: .dailyProteinGoal)
        try container.encode(dailyCarbsGoal, forKey: .dailyCarbsGoal)
        try container.encode(dailyFatGoal, forKey: .dailyFatGoal)
        try container.encode(gender, forKey: .gender)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(foodEntries, forKey: .foodEntries)
    }
    
    // Custom decoding for Firestore Timestamp
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        preferences = try container.decode([String: String].self, forKey: .preferences)
        fullName = try container.decode(String.self, forKey: .fullName)
        height = try container.decode(Double.self, forKey: .height)
        weight = try container.decode(Double.self, forKey: .weight)
        dailyCalorieGoal = try container.decode(Int.self, forKey: .dailyCalorieGoal)
        dailyProteinGoal = try container.decode(Int.self, forKey: .dailyProteinGoal)
        dailyCarbsGoal = try container.decode(Int.self, forKey: .dailyCarbsGoal)
        dailyFatGoal = try container.decode(Int.self, forKey: .dailyFatGoal)
        gender = try container.decode(UserGender.self, forKey: .gender)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        foodEntries = try container.decode([String: [FoodEntry]].self, forKey: .foodEntries)
    }
}

extension DateFormatter {
} 