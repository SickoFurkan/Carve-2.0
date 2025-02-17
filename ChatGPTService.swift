import Foundation

actor ChatGPTService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    init() {
        self.apiKey = Configuration.openAIApiKey
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        // Remove markdown code blocks and any whitespace
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
    
    func analyzeFoodEntry(_ entry: FoodEntry) async throws -> FoodAnalysis {
        print("🔄 Starting food analysis for: \(entry.name)")
        
        var messages: [[String: Any]] = [
            ["role": "system", "content": """
            You are a professional nutritionist and food analyst. Your task is to:
            1. Carefully analyze the food image or description provided
            2. Identify the exact type of food, cooking method, and main ingredients
            3. For different types of dishes:
               - Salads: identify greens, vegetables, proteins, dressings, toppings
               - Stir-fries: identify proteins, vegetables, sauce type, accompaniments (rice/noodles)
               - Main courses: identify primary protein, starches, vegetables, cooking method
               - Snacks: identify main components and preparation method
               - Desserts: identify main ingredients and type
               - Beverages: identify base and additions
            4. Calculate precise nutritional content for the specified portion size
            5. Return ONLY a JSON response in this exact format:
            {
                "calories": integer,
                "protein": integer,
                "carbs": integer,
                "fat": integer,
                "details": "precise 2-4 word description"
            }
            
            IMPORTANT RULES:
            - The 'details' field must be a precise 2-4 word description (e.g., "Grilled Chicken Salad", "Vegetable Stir-Fry Rice")
            - All nutritional values must be integers
            - Be very precise with nutritional calculations
            - Adjust values based on portion size
            - Consider ALL ingredients, including oils, sauces, and dressings
            - If you see rice or noodles, ALWAYS include them in the description
            - For stir-fries, always specify if served with rice/noodles
            - Base nutritional calculations on realistic portion sizes
            """]
        ]
        
        if let base64Image = entry.getBase64Image() {
            print("📸 Image provided for analysis")
            messages.append([
                "role": "user",
                "content": "Analyze nutritional information for \(entry.amount)g of food in this image: data:image/jpeg;base64,\(base64Image)"
            ])
        } else {
            print("📝 Text-based analysis for: \(entry.name)")
            messages.append([
                "role": "user",
                "content": "Analyze nutritional information for \(entry.amount)g of \(entry.name)"
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini-2024-07-18",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        print("📤 Sending request to OpenAI")
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ChatGPTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorString)")
            }
            throw NSError(domain: "ChatGPTService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status code \(httpResponse.statusCode)"])
        }
        
        print("✅ Received response from OpenAI")
        let decoder = JSONDecoder()
        let gptResponse = try decoder.decode(ChatGPTResponse.self, from: data)
        
        guard let content = gptResponse.choices.first?.message.content else {
            throw NSError(domain: "ChatGPTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get response content"])
        }
        
        // Clean the response before parsing
        let cleanedContent = cleanJSONResponse(content)
        print("🧹 Cleaned Response: \(cleanedContent)")
        
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "ChatGPTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert cleaned content to data"])
        }
        
        do {
            let analysis = try decoder.decode(FoodAnalysis.self, from: jsonData)
            print("✅ Successfully parsed food analysis")
            return analysis
        } catch {
            print("❌ JSON Parsing Error: \(error)")
            print("Attempted to parse: \(cleanedContent)")
            throw NSError(domain: "ChatGPTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse food analysis: \(error.localizedDescription)"])
        }
    }
}

private struct ChatGPTResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 
