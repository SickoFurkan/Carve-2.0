import SwiftUI
import FirebaseAuth
import AuthenticationServices
import FirebaseFirestore

struct WelcomeView: View {
    @State private var showOnboarding = false
    @State private var showLogin = false
    @EnvironmentObject var firebaseService: FirebaseService
    
    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                ZStack {
                    // Welcome Content
                    VStack {
                        Spacer()
                            .frame(height: 200)
                        
                        // Welcome Message
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Text("Welcome")
                                    .font(.system(size: 36, weight: .bold))
                                Text("to")
                                    .font(.system(size: 36, weight: .bold))
                                Text("👋")
                                    .font(.system(size: 36))
                            }
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            AnimatedTitle()
                        }
                        
                        Spacer()
                            .frame(minHeight: 100, maxHeight: .infinity)
                        
                        // Action Buttons
                        VStack(spacing: 24) {
                            RainbowButton(title: "Let's Start") {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showOnboarding = true
                                }
                            }
                            
                            HStack(spacing: 8) {
                                Text("Already have an account?")
                                    .foregroundColor(.primary)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                Button {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        showLogin = true
                                    }
                                } label: {
                                    Text("Log in")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                }
                            }
                            .font(.system(size: 16))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 80)
                    }
                    .opacity(showOnboarding || showLogin ? 0 : 1)
                    
                    // Onboarding View with transition
                    if showOnboarding {
                        OnboardingNameView(isPresented: $showOnboarding)
                            .transition(.move(edge: .trailing))
                    }
                    
                    // Login View with transition
                    if showLogin {
                        LoginView(isPresented: $showLogin, showOnboarding: $showOnboarding)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    NavigationView {
        WelcomeView()
            .environmentObject(FirebaseService.shared)
    }
}
