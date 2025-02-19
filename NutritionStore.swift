import Foundation

public struct DailyNutrition: Codable, Identifiable {
    public let id: UUID
    public let date: Date
    public var totalCalories: Int
    public var totalProtein: Int
    public var totalCarbs: Int
    public var totalFat: Int
    public var meals: [Meal]
    
    public init(date: Date = Date(), totalCalories: Int = 0, totalProtein: Int = 0, totalCarbs: Int = 0, totalFat: Int = 0, meals: [Meal] = []) {
        self.id = UUID()
        self.date = date
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.meals = meals
    }
}

public class NutritionStore: ObservableObject {
    @Published public var dailyNutritions: [DailyNutrition] = []
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "dailyNutritions"
    
    public init() {
        loadNutritions()
    }
    
    public func addMeal(_ meal: Meal, for date: Date) {
        if let index = dailyNutritions.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dailyNutritions[index].meals.append(meal)
            updateTotals(at: index)
        } else {
            let newDaily = DailyNutrition(date: date, meals: [meal])
            dailyNutritions.append(newDaily)
            updateTotals(at: dailyNutritions.count - 1)
        }
        saveNutritions()
    }
    
    private func updateTotals(at index: Int) {
        let meals = dailyNutritions[index].meals
        dailyNutritions[index].totalCalories = meals.reduce(0) { $0 + $1.calories }
        dailyNutritions[index].totalProtein = meals.reduce(0) { $0 + $1.protein }
        dailyNutritions[index].totalCarbs = meals.reduce(0) { $0 + $1.carbs }
        dailyNutritions[index].totalFat = meals.reduce(0) { $0 + $1.fat }
    }
    
    public func getNutrition(for date: Date) -> DailyNutrition {
        if let nutrition = dailyNutritions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return nutrition
        }
        return DailyNutrition(date: date)
    }
    
    public func getMealsForDate(_ date: Date) -> [Meal] {
        if let nutrition = dailyNutritions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return nutrition.meals
        }
        return []
    }
    
    public func getTodaysTotalCalories() -> Int {
        getNutrition(for: Date()).totalCalories
    }
    
    public func getTodaysTotalProtein() -> Int {
        getNutrition(for: Date()).totalProtein
    }
    
    public func getTodaysTotalCarbs() -> Int {
        getNutrition(for: Date()).totalCarbs
    }
    
    public func getTodaysTotalFat() -> Int {
        getNutrition(for: Date()).totalFat
    }
    
    public func getTotalCaloriesForDate(_ date: Date) -> Int {
        getNutrition(for: date).totalCalories
    }
    
    private func saveNutritions() {
        if let encoded = try? JSONEncoder().encode(dailyNutritions) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadNutritions() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DailyNutrition].self, from: data) {
            dailyNutritions = decoded
        }
    }
} 