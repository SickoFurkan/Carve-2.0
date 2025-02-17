import Foundation
import FirebaseFirestore

public struct UserProfile: Codable, Identifiable {
    public let id: String
    public var email: String
    public var username: String
    public var fullName: String
    public var birthDate: Date
    public var gender: Gender
    public var height: Double
    public var weight: Double
    public let createdAt: Date
    public var dailyCalorieGoal: Int
    public var dailyProteinGoal: Int
    public var dailyCarbsGoal: Int
    public var dailyFatGoal: Int
    public var foodDiary: [String: DailyFoodData]?
    
    public struct DailyFoodData: Codable {
        public var date: Date
        public var entries: [FoodEntry]
        public var totals: MacroTotals
        
        enum CodingKeys: String, CodingKey {
            case date, entries, totals
        }
        
        public init(date: Date, entries: [FoodEntry], totals: MacroTotals) {
            self.date = date
            self.entries = entries
            self.totals = totals
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let timestamp = try? container.decode(Timestamp.self, forKey: .date) {
                date = timestamp.dateValue()
            } else {
                date = try container.decode(Date.self, forKey: .date)
            }
            
            entries = try container.decode([FoodEntry].self, forKey: .entries)
            totals = try container.decode(MacroTotals.self, forKey: .totals)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(date, forKey: .date)
            try container.encode(entries, forKey: .entries)
            try container.encode(totals, forKey: .totals)
        }
    }
    
    public var bmi: Double {
        guard height > 0 else { return 0 }
        return weight / pow(height/100, 2)
    }
    
    public var bmiCategory: BMICategory {
        BMICategory.category(for: bmi)
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case fullName
        case birthDate
        case gender
        case height
        case weight
        case createdAt
        case dailyCalorieGoal
        case dailyProteinGoal
        case dailyCarbsGoal
        case dailyFatGoal
        case foodDiary
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        fullName = try container.decode(String.self, forKey: .fullName)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .birthDate) {
            birthDate = timestamp.dateValue()
        } else {
            birthDate = try container.decode(Date.self, forKey: .birthDate)
        }
        
        gender = try container.decode(Gender.self, forKey: .gender)
        height = try container.decode(Double.self, forKey: .height)
        weight = try container.decode(Double.self, forKey: .weight)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        dailyCalorieGoal = try container.decode(Int.self, forKey: .dailyCalorieGoal)
        dailyProteinGoal = try container.decode(Int.self, forKey: .dailyProteinGoal)
        dailyCarbsGoal = try container.decode(Int.self, forKey: .dailyCarbsGoal)
        dailyFatGoal = try container.decode(Int.self, forKey: .dailyFatGoal)
        
        // Handle foodDiary decoding
        if let diaryContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .foodDiary) {
            foodDiary = [:]
            for key in diaryContainer.allKeys {
                if let dailyDataContainer = try? diaryContainer.nestedContainer(keyedBy: DailyFoodDataKeys.self, forKey: key),
                   let dateTimestamp = try? dailyDataContainer.decode(Timestamp.self, forKey: .date),
                   let entries = try? dailyDataContainer.decode([FoodEntry].self, forKey: .entries),
                   let totals = try? dailyDataContainer.decode(MacroTotals.self, forKey: .totals) {
                    
                    foodDiary?[key.stringValue] = DailyFoodData(
                        date: dateTimestamp.dateValue(),
                        entries: entries,
                        totals: totals
                    )
                }
            }
        } else {
            foodDiary = nil
        }
    }
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    private enum DailyFoodDataKeys: String, CodingKey {
        case date
        case entries
        case totals
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(Timestamp(date: birthDate), forKey: .birthDate)
        try container.encode(gender, forKey: .gender)
        try container.encode(height, forKey: .height)
        try container.encode(weight, forKey: .weight)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(dailyCalorieGoal, forKey: .dailyCalorieGoal)
        try container.encode(dailyProteinGoal, forKey: .dailyProteinGoal)
        try container.encode(dailyCarbsGoal, forKey: .dailyCarbsGoal)
        try container.encode(dailyFatGoal, forKey: .dailyFatGoal)
        
        // Handle foodDiary encoding
        if let foodDiary = foodDiary {
            var diaryContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .foodDiary)
            for (date, dailyData) in foodDiary {
                let key = DynamicCodingKeys(stringValue: date)!
                var dailyContainer = diaryContainer.nestedContainer(keyedBy: DailyFoodDataKeys.self, forKey: key)
                
                try dailyContainer.encode(Timestamp(date: dailyData.date), forKey: .date)
                try dailyContainer.encode(dailyData.entries, forKey: .entries)
                try dailyContainer.encode(dailyData.totals, forKey: .totals)
            }
        }
    }
    
    public init(id: String,
               email: String = "",
               username: String = "",
               fullName: String = "",
               birthDate: Date = Date(),
               gender: Gender = .preferNotToSay,
               height: Double = 0,
               weight: Double = 0,
               createdAt: Date = Date(),
               dailyCalorieGoal: Int = 0,
               dailyProteinGoal: Int = 0,
               dailyCarbsGoal: Int = 0,
               dailyFatGoal: Int = 0,
               foodDiary: [String: DailyFoodData]? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.fullName = fullName
        self.birthDate = birthDate
        self.gender = gender
        self.height = height
        self.weight = weight
        self.createdAt = createdAt
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.foodDiary = foodDiary
    }
    
    public func addFoodEntry(_ entry: FoodEntry, for date: Date) {
        // This method will be handled by FirebaseService
    }
    
    public func getEntries(for date: Date = Date()) -> [FoodEntry]? {
        // This method will be handled by FirebaseService
        return nil
    }
}

// MARK: - Firestore Conversion
extension UserProfile {
    public var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "username": username,
            "fullName": fullName,
            "birthDate": Timestamp(date: birthDate),
            "gender": gender.rawValue,
            "height": height,
            "weight": weight,
            "createdAt": Timestamp(date: createdAt),
            "dailyCalorieGoal": dailyCalorieGoal,
            "dailyProteinGoal": dailyProteinGoal,
            "dailyCarbsGoal": dailyCarbsGoal,
            "dailyFatGoal": dailyFatGoal
        ]
        
        if let foodDiary = foodDiary {
            var diaryData: [String: Any] = [:]
            for (date, dailyData) in foodDiary {
                diaryData[date] = [
                    "date": Timestamp(date: dailyData.date),
                    "entries": dailyData.entries.map { $0.firestoreData },
                    "totals": [
                        "calories": dailyData.totals.calories,
                        "protein": dailyData.totals.protein,
                        "carbs": dailyData.totals.carbs,
                        "fat": dailyData.totals.fat
                    ]
                ]
            }
            data["foodDiary"] = diaryData
        }
        
        return data
    }
    
    public static func from(firestoreData data: [String: Any]) -> UserProfile? {
        guard let id = data["id"] as? String,
              let email = data["email"] as? String,
              let username = data["username"] as? String,
              let fullName = data["fullName"] as? String,
              let birthDateTimestamp = data["birthDate"] as? Timestamp,
              let genderString = data["gender"] as? String,
              let gender = Gender(rawValue: genderString),
              let height = data["height"] as? Double,
              let weight = data["weight"] as? Double,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let dailyCalorieGoal = data["dailyCalorieGoal"] as? Int,
              let dailyProteinGoal = data["dailyProteinGoal"] as? Int,
              let dailyCarbsGoal = data["dailyCarbsGoal"] as? Int,
              let dailyFatGoal = data["dailyFatGoal"] as? Int else {
            return nil
        }
        
        var foodDiary: [String: DailyFoodData]?
        if let diaryData = data["foodDiary"] as? [String: [String: Any]] {
            foodDiary = [:]
            for (date, dailyData) in diaryData {
                if let dateTimestamp = dailyData["date"] as? Timestamp,
                   let entriesData = dailyData["entries"] as? [[String: Any]],
                   let totalsData = dailyData["totals"] as? [String: Int] {
                    
                    let entries = entriesData.compactMap { FoodEntry.from(firestoreData: $0) }
                    let totals = MacroTotals(
                        calories: totalsData["calories"] ?? 0,
                        protein: totalsData["protein"] ?? 0,
                        carbs: totalsData["carbs"] ?? 0,
                        fat: totalsData["fat"] ?? 0
                    )
                    
                    foodDiary?[date] = DailyFoodData(
                        date: dateTimestamp.dateValue(),
                        entries: entries,
                        totals: totals
                    )
                }
            }
        }
        
        return UserProfile(
            id: id,
            email: email,
            username: username,
            fullName: fullName,
            birthDate: birthDateTimestamp.dateValue(),
            gender: gender,
            height: height,
            weight: weight,
            createdAt: createdAtTimestamp.dateValue(),
            dailyCalorieGoal: dailyCalorieGoal,
            dailyProteinGoal: dailyProteinGoal,
            dailyCarbsGoal: dailyCarbsGoal,
            dailyFatGoal: dailyFatGoal,
            foodDiary: foodDiary
        )
    }
} 