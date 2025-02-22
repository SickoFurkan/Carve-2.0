import SwiftUI

struct AnimatedTitle: View {
    @State private var currentIndex = 0
    private let titles = ["Carve", "Progress", "Comfort", "Growth", "Gains", "Strength", "Vitality", "Wellness", "Endurance"]
    @State private var opacity: Double = 1
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Text(titles[currentIndex])
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(.white)
            .opacity(opacity)
            .offset(y: offset)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .onAppear {
                startAnimation()
            }
    }
    
    private func startAnimation() {
        let animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
                offset = -20
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentIndex = (currentIndex + 1) % titles.count
                offset = 20
                
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 1
                    offset = 0
                }
            }
        }
        
        // Start the animation immediately
        animationTimer.fire()
    }
}

#Preview {
    ZStack {
        Color.black
        AnimatedTitle()
    }
} 