import Foundation

public struct Workout: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let duration: Int
    public let muscleGroups: [MuscleGroup]
    public let date: Date
    
    public init(name: String, duration: Int, muscleGroups: [MuscleGroup], date: Date) {
        self.id = UUID()
        self.name = name
        self.duration = duration
        self.muscleGroups = muscleGroups
        self.date = date
    }
} 