import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            if viewModel.isEditing {
                TextField("Volledige naam", text: $viewModel.tempFullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .font(.title)
            } else {
                Text(profile.fullName)
                    .font(.title)
                    .bold()
            }
            
            HStack(spacing: 20) {
                if viewModel.isEditing {
                    StatView(value: viewModel.tempWeight, unit: "kg")
                    StatView(value: viewModel.tempHeight, unit: "cm")
                    StatView(value: String(format: "%.1f", viewModel.calculateBMI()), unit: "BMI")
                } else {
                    StatView(value: String(format: "%.0f", profile.weight), unit: "kg")
                    StatView(value: String(format: "%.0f", profile.height), unit: "cm")
                    StatView(value: String(format: "%.1f", profile.bmi), unit: "BMI")
                }
            }
            
            if !viewModel.isEditing {
                Text(profile.bmiCategory.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
} 