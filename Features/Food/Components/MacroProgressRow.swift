import SwiftUI

public struct MacroProgressRow: View {
    let label: String
    let consumed: Int
    let goal: Int
    let unit: String
    let color: Color
    
    public init(label: String, consumed: Int, goal: Int, unit: String, color: Color) {
        self.label = label
        self.consumed = consumed
        self.goal = goal
        self.unit = unit
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(consumed)/\(goal)\(unit)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 6)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(consumed) / CGFloat(goal), height: 6)
                        .foregroundColor(color)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
    }
} 