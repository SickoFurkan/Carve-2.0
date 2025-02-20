import SwiftUI

struct AuroraBackground<Content: View>: View {
    let content: Content
    @State private var phase: CGFloat = 0
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Aurora effect
            GeometryReader { geometry in
                ZStack {
                    // Base gradient layers
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.5),
                            Color.purple.opacity(0.5),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: geometry.size.width * 0.1,
                        endRadius: geometry.size.width * 0.7
                    )
                    
                    // Animated aurora layers
                    ForEach(0..<3) { index in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.4),
                                Color.purple.opacity(0.4),
                                Color.indigo.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blur(radius: 40)
                        .rotationEffect(.degrees(Double(index) * 60 + Double(phase)))
                        .animation(
                            Animation.linear(duration: 15)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 2),
                            value: phase
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: geometry.size.height * 0.2) // Move aurora effect down
            }
            .ignoresSafeArea()
            
            // Content
            content
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: true)) {
                phase = 360
            }
        }
    }
}

// Preview provider
struct AuroraBackground_Previews: PreviewProvider {
    static var previews: some View {
        AuroraBackground {
            VStack(spacing: 20) {
                Text("Background lights are cool you know.")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("And this, is chemical burn.")
                    .font(.system(size: 20, weight: .light))
                
                Button(action: {
                    print("Debug tapped")
                }) {
                    Text("Debug now")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .cornerRadius(25)
                }
            }
            .padding()
            .foregroundColor(.primary)
        }
    }
} 