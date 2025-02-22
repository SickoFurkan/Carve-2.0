import SwiftUI

struct OnboardingNavigationBar: View {
    @Binding var currentStep: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if currentStep > 1 {
                        currentStep -= 1
                    } else {
                        isPresented = false
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                    
                    Text("Back")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Text("Step \(currentStep) of 5")
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .regular))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .ignoresSafeArea(edges: .top)
        )
    }
}

struct OnboardingProgressBar: View {
    let currentStep: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 3)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * (CGFloat(currentStep)/5), height: 3)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Preview
struct OnboardingComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OnboardingNavigationBar(currentStep: .constant(1), isPresented: .constant(true))
            OnboardingProgressBar(currentStep: 1)
            TextField("Sample", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .padding()
        }
    }
} 
