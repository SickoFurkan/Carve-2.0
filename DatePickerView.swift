import SwiftUI

public struct DatePickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    
    public var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Selecteer een datum",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
            }
            .navigationBarItems(
                trailing: Button("Gereed") {
                    isPresented = false
                }
            )
            .navigationTitle("Selecteer Datum")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
    }
} 