import SwiftUI

public struct CardView<Content: View>: View {
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 5)
    }
}

// MARK: - View Modifiers
public extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 5)
    }
} 