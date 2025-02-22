import Foundation
import UIKit

struct AnalyzedFood: Codable {
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let items: [String]
}

class FoodAnalysisService: ObservableObject {
    static let shared = FoodAnalysisService()
    private let openAIKey = "YOUR_OPENAI_KEY" // Replace with your OpenAI API key
    
    func analyzeFood(image: UIImage) async throws -> AnalyzedFood {
        // 1. Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FoodAnalysis", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        let base64Image = imageData.base64EncodedString()
        
        // 2. Create the API request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. Prepare the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Analyze this food image and provide nutritional information in the following JSON format: {\"name\": \"Food name\", \"calories\": number, \"protein\": number, \"carbs\": number, \"fat\": number, \"items\": [\"item1\", \"item2\", etc]}"
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 4. Make the request
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // 5. Parse the response
        let response = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
        guard let content = response.choices.first?.message.content,
              let jsonData = content.data(using: .utf8),
              let foodInfo = try? JSONDecoder().decode(AnalyzedFood.self, from: jsonData) else {
            throw NSError(domain: "FoodAnalysis", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        return foodInfo
    }
}

// ChatGPT Response Models
struct ChatGPTResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
} 