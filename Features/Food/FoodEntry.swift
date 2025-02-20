import Foundation
import UIKit
import FirebaseFirestore

public struct FoodEntry: Identifiable, Codable {
    public var id: String
    public var name: String
    public var description: String
    public var amount: Int
    public var calories: Int
    public var protein: Int
    public var carbs: Int
    public var fat: Int
    public var imageBase64: String?
    public var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, amount, calories, protein, carbs, fat, imageBase64, timestamp
    }
    
    public init(name: String, description: String = "", amount: Int, calories: Int, protein: Int, carbs: Int, fat: Int, imageBase64: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.amount = amount
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.imageBase64 = imageBase64
        self.timestamp = Date()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        amount = try container.decode(Int.self, forKey: .amount)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fat = try container.decode(Int.self, forKey: .fat)
        imageBase64 = try container.decodeIfPresent(String.self, forKey: .imageBase64)
        
        // Handle Timestamp decoding
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(amount, forKey: .amount)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fat, forKey: .fat)
        try container.encodeIfPresent(imageBase64, forKey: .imageBase64)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    // Helper method to get base64 image of the image
    public func getBase64Image() -> String? {
        return imageBase64
    }
}

// MARK: - Firestore Conversion
extension FoodEntry {
    public var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "description": description,
            "amount": amount,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "timestamp": Timestamp(date: timestamp)
        ]
        
        if let imageBase64 = imageBase64 {
            data["imageBase64"] = imageBase64
        }
        
        return data
    }
    
    public static func from(firestoreData data: [String: Any]) -> FoodEntry? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let amount = data["amount"] as? Int,
              let calories = data["calories"] as? Int,
              let protein = data["protein"] as? Int,
              let carbs = data["carbs"] as? Int,
              let fat = data["fat"] as? Int,
              let timestampData = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        var entry = FoodEntry(
            name: name,
            description: data["description"] as? String ?? "",
            amount: amount,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            imageBase64: data["imageBase64"] as? String
        )
        
        entry.id = id
        entry.timestamp = timestampData.dateValue()
        
        return entry
    }
}

// MARK: - Array Extension for Totals
public extension Array where Element == FoodEntry {
    var totals: MacroTotals {
        let calories = self.reduce(0) { $0 + $1.calories }
        let protein = self.reduce(0) { $0 + $1.protein }
        let carbs = self.reduce(0) { $0 + $1.carbs }
        let fat = self.reduce(0) { $0 + $1.fat }
        return MacroTotals(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
}

public struct MacroTotals: Codable {
    public let calories: Int
    public let protein: Int
    public let carbs: Int
    public let fat: Int
    
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbs, fat
    }
    
    public init(calories: Int, protein: Int, carbs: Int, fat: Int) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fat = try container.decode(Int.self, forKey: .fat)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fat, forKey: .fat)
    }
} 