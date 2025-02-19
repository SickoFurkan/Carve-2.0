import SwiftUI

struct StatView: View {
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
} 