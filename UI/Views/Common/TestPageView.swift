import SwiftUI

struct TestPageView: View {
    let pageNumber: Int
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Content Area
                        VStack(spacing: 16) {
                            Text("Test Page \(pageNumber)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("This is a test page to demonstrate navigation")
                                .foregroundColor(.secondary)
                            
                            // Add some dummy content
                            ForEach(1...5, id: \.self) { index in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("Test Item \(index)")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                if index != 5 {
                                    Divider()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    }
                    .padding(.top, 100)
                }
                
                // Custom Navigation Bar
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Text("Test Page \(pageNumber)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    TestPageView(pageNumber: 1)
} 