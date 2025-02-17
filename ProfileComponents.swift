import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
    }
}

struct StatView: View {
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .bold()
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    VStack {
        InfoRow(label: "Test Label", value: "Test Value")
        StatView(value: "75", unit: "kg")
    }
    .padding()
} 