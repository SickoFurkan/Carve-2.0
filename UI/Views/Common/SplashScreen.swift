import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @EnvironmentObject var firebaseService: FirebaseService
    
    var body: some View {
        Group {
            if isActive {
                if firebaseService.isAuthenticated {
                    ContentView()
                } else {
                    WelcomeView()
                }
            } else {
                ZStack {
                    // Background Image with Gradients
                    GeometryReader { geometry in
                        Image("splash-background")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .overlay {
                                VStack(spacing: 0) {
                                    // Top gradient
                                    LinearGradient(
                                        colors: [
                                            .black.opacity(0.8),
                                            .clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                    .frame(height: geometry.size.height / 3)
                                    
                                    Spacer()
                                    
                                    // Bottom gradient
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .black.opacity(0.9)
                                        ],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                    .frame(height: geometry.size.height / 3)
                                }
                            }
                    }
                    .ignoresSafeArea()
                    
                    // Content
                    VStack {
                        // App Name at the top
                        Text("Carve")
                            .font(.system(size: 72, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                            .overlay {
                                Text("Carve")
                                    .font(.system(size: 72, weight: .heavy))
                                    .foregroundColor(.white.opacity(0.3))
                                    .offset(x: 1, y: 1)
                            }
                        
                        Spacer()
                        
                        // Creator Credit at the bottom
                        VStack(spacing: 8) {
                            Text("Project by")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 3)
                            Text("Furkan Çeliker")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 3)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.vertical, 60)
                    .padding(.horizontal)
                    .scaleEffect(size)
                    .opacity(opacity)
                }
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
        .environmentObject(FirebaseService.shared)
} 