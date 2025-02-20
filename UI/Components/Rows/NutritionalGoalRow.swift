import SwiftUI

struct NutritionalGoalRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .frame(width: 80)
            Text(unit)
        }
    }
} 