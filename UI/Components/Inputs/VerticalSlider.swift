import SwiftUI

struct VerticalSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            Text("\(Int(value))\(unit)")
                .font(.title)
                .foregroundColor(.black)
            
            Slider(
                value: $value,
                in: range,
                step: step
            )
            .rotationEffect(.degrees(-90))
            .frame(width: 120, height: 120)
        }
    }
} 