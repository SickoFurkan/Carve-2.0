import Foundation
import UIKit

actor ChatGPTService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 2.0 // Minimum 2 seconds between requests
    private let networkMonitor = NetworkMonitor.shared
    private let maxRetries = 3
    private let maxImageSize = 1024 * 1024 // 1MB
    private let rateLimitBackoff: TimeInterval = 5.0 // 5 seconds backoff for rate limits
    
    init() {
        self.apiKey = Configuration.openAIAPIKey
    }
    
    private func optimizeImage(_ image: UIImage) -> String? {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Gradually reduce quality until we get under maxImageSize
        while let data = imageData, data.count > maxImageSize && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let finalData = imageData else { return nil }
        return finalData.base64EncodedString()
    }
    
    private func validateAndOptimizeEntry(_ entry: FoodEntry) throws -> FoodEntry {
        var optimizedEntry = entry
        
        // Validate and trim text content
        optimizedEntry.name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        optimizedEntry.description = entry.description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure we have either a name or an image
        guard !optimizedEntry.name.isEmpty || entry.getBase64Image() != nil else {
            throw AnalysisError.invalidInput("Please provide either a food name or an image")
        }
        
        // If we have an image, optimize it
        if let base64Image = entry.getBase64Image(),
           let imageData = Data(base64Encoded: base64Image),
           let image = UIImage(data: imageData) {
            optimizedEntry.imageBase64 = optimizeImage(image)
        }
        
        return optimizedEntry
    }
    
    func analyzeFoodEntry(_ entry: FoodEntry) async throws -> FoodAnalysis {
        // Check network connectivity
        guard networkMonitor.isConnected else {
            throw AnalysisError.noConnection
        }
        
        // Validate and optimize the entry
        let optimizedEntry = try validateAndOptimizeEntry(entry)
        print("🔄 Starting food analysis for: \(optimizedEntry.name)")
        
        // Wait for rate limit if needed
        try await waitForRateLimit()
        
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
            """]
        ]
        
        let userMessage: String
        if let base64Image = optimizedEntry.getBase64Image() {
            print("📸 Image provided for analysis")
            userMessage = "Analyze nutritional information for \(optimizedEntry.amount)g of food in this image: data:image/jpeg;base64,\(base64Image)"
        } else {
            print("📝 Text-based analysis for: \(optimizedEntry.name)")
            userMessage = "Analyze nutritional information for \(optimizedEntry.amount)g of \(optimizedEntry.name)"
        }
        
        messages.append(["role": "user", "content": userMessage])
        
        var attempt = 0
        var lastError: Error?
        
        while attempt < maxRetries {
            do {
                try await waitForRateLimit()
                
                let requestBody: [String: Any] = [
                    "model": "gpt-4o-mini-2024-07-18",
                    "messages": messages,
                    "temperature": 0.7,
                    "max_tokens": 500
                ]
                
                print("📤 Sending request to OpenAI (Attempt \(attempt + 1)/\(maxRetries))")
                var request = URLRequest(url: baseURL)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30 // 30 second timeout
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AnalysisError.invalidResponse
                }
                
                if httpResponse.statusCode == 429 {
                    attempt += 1
                    if attempt < maxRetries {
                        try await handleRateLimitRetry(attempt: attempt)
                        continue
                    } else {
                        throw AnalysisError.rateLimitExceeded
                    }
                }
                
                if httpResponse.statusCode != 200 {
                    throw handleAPIError(httpResponse.statusCode, data: data)
                }
                
                print("✅ Received response from OpenAI")
                let decoder = JSONDecoder()
                let gptResponse = try decoder.decode(ChatGPTResponse.self, from: data)
                
                guard let content = gptResponse.choices.first?.message.content else {
                    throw AnalysisError.noContent
                }
                
                let cleanedContent = cleanJSONResponse(content)
                print("🧹 Cleaned Response: \(cleanedContent)")
                
                guard let jsonData = cleanedContent.data(using: .utf8) else {
                    throw AnalysisError.invalidJSON
                }
                
                let analysis = try decoder.decode(FoodAnalysis.self, from: jsonData)
                print("✅ Successfully parsed food analysis")
                return analysis
                
            } catch {
                lastError = error
                if error is AnalysisError {
                    throw error
                }
                attempt += 1
                if attempt == maxRetries {
                    throw AnalysisError.maxRetriesExceeded(error)
                }
                try await Task.sleep(nanoseconds: UInt64(Double(attempt) * 2.0 * 1_000_000_000))
            }
        }
        
        throw lastError ?? AnalysisError.unknown
    }
    
    enum AnalysisError: LocalizedError {
        case noConnection
        case invalidInput(String)
        case invalidResponse
        case noContent
        case invalidJSON
        case maxRetriesExceeded(Error)
        case rateLimitExceeded
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .noConnection:
                return NSLocalizedString("no_internet_connection", comment: "")
            case .invalidInput(let message):
                return message
            case .invalidResponse:
                return NSLocalizedString("invalid_response", comment: "")
            case .noContent:
                return NSLocalizedString("no_content_received", comment: "")
            case .invalidJSON:
                return NSLocalizedString("invalid_json_response", comment: "")
            case .maxRetriesExceeded(let error):
                return String(format: NSLocalizedString("max_retries_exceeded", comment: ""), error.localizedDescription)
            case .rateLimitExceeded:
                return NSLocalizedString("rate_limit_error", comment: "")
            case .unknown:
                return NSLocalizedString("unknown_error", comment: "")
            }
        }
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        // Remove markdown code blocks and any whitespace
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
    
    private func handleAPIError(_ statusCode: Int, data: Data) -> Error {
        let errorMessage: String
        if statusCode == 429 {
            errorMessage = "Rate limit exceeded. Please try again in a few seconds."
        } else if let errorData = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
            errorMessage = errorData.error.message
        } else if let errorString = String(data: data, encoding: .utf8) {
            errorMessage = "API Error: \(errorString)"
        } else {
            errorMessage = "Unknown API error occurred"
        }
        return NSError(domain: "ChatGPTService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
    
    private func waitForRateLimit() async throws {
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumRequestInterval {
                let waitTime = minimumRequestInterval - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    private func handleRateLimitRetry(attempt: Int) async throws {
        print("⚠️ Rate limit exceeded, implementing exponential backoff...")
        let backoffTime = rateLimitBackoff * pow(2.0, Double(attempt))
        print("   Waiting for \(String(format: "%.1f", backoffTime)) seconds before retry...")
        try await Task.sleep(nanoseconds: UInt64(backoffTime * 1_000_000_000))
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

private struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
    
    struct OpenAIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
} 
