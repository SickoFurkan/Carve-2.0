import Foundation

// MARK: - Core Models
public struct Meal: Identifiable, Hashable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let calories: Int
    public let protein: Int
    public let carbs: Int
    public let fat: Int
    public let date: Date
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public init(id: UUID = UUID(), name: String, calories: Int, protein: Int, carbs: Int = 0, fat: Int = 0, date: Date = Date()) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
    }
    
    // Implement Equatable
    public static func == (lhs: Meal, rhs: Meal) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Implement Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct Friend: Identifiable, Hashable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let calories: Int
    public let protein: Int
    public let carbs: Int
    public let fat: Int
    public let todaysMeals: [Meal]
    
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, carbs, fat, todaysMeals
    }
    
    public init(id: UUID = UUID(), name: String, calories: Int, protein: Int, carbs: Int, fat: Int, todaysMeals: [Meal]) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.todaysMeals = todaysMeals
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fat = try container.decode(Int.self, forKey: .fat)
        todaysMeals = try container.decode([Meal].self, forKey: .todaysMeals)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fat, forKey: .fat)
        try container.encode(todaysMeals, forKey: .todaysMeals)
    }
    
    // Implement Equatable
    public static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Implement Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Models
public struct FoodItem: Identifiable, Codable {
    public var id: UUID = UUID()
    public let name: String
    public let grams: Int
    
    public init(name: String, grams: Int) {
        self.name = name
        self.grams = grams
    }
}

public struct Recipe: Identifiable, Codable {
    public var id: UUID = UUID()
    public let title: String
    public let description: String
    public let image: String
    
    public init(title: String, description: String, image: String) {
        self.title = title
        self.description = description
        self.image = image
    }
}

public struct AnalyzedPhoto: Identifiable, Codable {
    public var id: UUID = UUID()
    public let imageUrl: String
    public let date: String
    public let calories: Int
    public let mainIngredient: String
    
    public init(imageUrl: String, date: String, calories: Int, mainIngredient: String) {
        self.imageUrl = imageUrl
        self.date = date
        self.calories = calories
        self.mainIngredient = mainIngredient
    }
}

public struct FoodPost: Identifiable, Codable {
    public var id: UUID = UUID()
    public let friendName: String
    public let foodName: String
    public let image: String
    public let time: String
    
    public init(friendName: String, foodName: String, image: String, time: String) {
        self.friendName = friendName
        self.foodName = foodName
        self.image = image
        self.time = time
    }
}

public struct Story: Codable {
    public let author: String
    public let title: String
    public let content: String
    public let tip: String
    public var likes: Int
    
    public init(author: String, title: String, content: String, tip: String, likes: Int = 0) {
        self.author = author
        self.title = title
        self.content = content
        self.tip = tip
        self.likes = likes
    }
}

// MARK: - Analysis Models
public struct FoodAnalysis: Codable {
    public let calories: Int
    public let protein: Int
    public let carbs: Int
    public let fat: Int
    public let details: String
    
    public init(calories: Int, protein: Int, carbs: Int, fat: Int, details: String) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.details = details
    }
} 
