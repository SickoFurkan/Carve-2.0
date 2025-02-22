import SwiftUI
import Foundation

struct BodyMeasurementsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Body Measurements")
                .font(.title2)
                .bold()
            
            HStack {
                TextField("Height", text: $viewModel.height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Text("cm")
            }
            
            if !viewModel.height.isEmpty && !viewModel.isValidHeight {
                Text("Enter a valid height (100-250 cm)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                TextField("Weight", text: $viewModel.weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Text("kg")
            }
            
            if !viewModel.weight.isEmpty && !viewModel.isValidWeight {
                Text("Enter a valid weight (30-300 kg)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if viewModel.isValidHeight && viewModel.isValidWeight,
               let height = Double(viewModel.height),
               let weight = Double(viewModel.weight) {
                let bmi = weight / pow(height/100, 2)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your BMI: \(String(format: "%.1f", bmi))")
                        .font(.headline)
                    
                    let category = BMICategory.category(for: bmi)
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    BodyMeasurementsView(viewModel: OnboardingViewModel())
} 