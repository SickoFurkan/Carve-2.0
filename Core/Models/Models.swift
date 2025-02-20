import Foundation

// MARK: - Core Models
public struct Meal: Identifiable, Hashable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let calories: Int
    public let protein: Int
    public let carbs: Int
    public let fat: Int
    public let time: String
    
    public init(id: UUID = UUID(), name: String, calories: Int, protein: Int, carbs: Int = 0, fat: Int = 0, time: String) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.time = time
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
    
    public init(id: UUID = UUID(), name: String, calories: Int, protein: Int, carbs: Int, fat: Int, todaysMeals: [Meal]) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.todaysMeals = todaysMeals
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
