import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    @Binding var editableValue: String
    var isEditing: Bool = false
    var isDisabled: Bool = false
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
        self._editableValue = .constant("")
        self.isEditing = false
    }
    
    init(label: String, editableValue: Binding<String>, isDisabled: Bool = false) {
        self.label = label
        self.value = ""
        self._editableValue = editableValue
        self.isEditing = true
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            if isEditing {
                TextField(label, text: $editableValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                    .frame(width: 200)
                    .disabled(isDisabled)
            } else {
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
} 