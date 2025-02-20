import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedPage: Int?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if isShowing {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isShowing = false
                            }
                        }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Menu")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Divider()
                            }
                            .padding(.vertical)
                            
                            // Menu Items
                            ForEach(1...3, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        selectedPage = index
                                        isShowing = false
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "number.\(index).circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                        
                                        Text("Test Page \(index)")
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedPage == index {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                            
                            Spacer()
                            
                            // Back to Main Button
                            if selectedPage != nil {
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        selectedPage = nil
                                        isShowing = false
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "house.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                        
                                        Text("Back to Main")
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        .padding()
                        .frame(width: min(geometry.size.width * 0.75, 300))
                        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .transition(.move(edge: .leading))
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true), selectedPage: .constant(nil))
} 