import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .submitLabel(.done)
            .onSubmit {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                             to: nil, 
                                             from: nil, 
                                             for: nil)
            }
    }
}

struct CustomSecureFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .submitLabel(.done)
            .onSubmit {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                             to: nil, 
                                             from: nil, 
                                             for: nil)
            }
            .privacySensitive(true)
    }
} 