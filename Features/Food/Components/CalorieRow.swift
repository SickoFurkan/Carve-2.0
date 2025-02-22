import SwiftUI

struct CalorieRow: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    let value: String
    let target: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .bold()
            Text("/\(target)")
                .foregroundColor(.gray)
            Text(unit)
                .foregroundColor(.gray)
        }
    }
}

struct MacroRow: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    let value: String
    let target: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .bold()
            Text("/\(target)")
                .foregroundColor(.gray)
            Text(unit)
                .foregroundColor(.gray)
        }
    }
} 