import Foundation

public struct Meal: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let calories: Int
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let date: Date
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
    }
} 