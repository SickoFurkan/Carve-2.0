import SwiftUI

struct EditableInfoRow: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            TextField(label, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .frame(width: 200)
        }
    }
} 