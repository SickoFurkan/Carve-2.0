import SwiftUI
import Foundation

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            // Progress Indicator
            if !viewModel.requiredSteps.isEmpty {
                ProgressView(value: Double(viewModel.currentStep + 1), total: Double(viewModel.requiredSteps.count))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
            
            // Step Content
            if let currentStep = viewModel.requiredSteps.first(where: { $0.rawValue == viewModel.currentStep }) {
                switch currentStep {
                case .accountInfo:
                    accountInfoView
                case .personalInfo:
                    personalInfoView
                case .bodyMeasurements:
                    bodyMeasurementsView
                case .nutritionGoals:
                    nutritionGoalsView
                }
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                if viewModel.currentStep > 0 {
                    Button("Vorige") {
                        viewModel.previousStep()
                    }
                }
                
                Spacer()
                
                if let currentIndex = viewModel.requiredSteps.firstIndex(where: { $0.rawValue == viewModel.currentStep }) {
                    Button(currentIndex == viewModel.requiredSteps.count - 1 ? "Voltooien" : "Volgende") {
                        if currentIndex == viewModel.requiredSteps.count - 1 {
                            Task {
                                await viewModel.saveProfile()
                            }
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .disabled(!viewModel.canProceedToNextStep)
                }
            }
            .padding()
        }
        .onChange(of: viewModel.shouldDismiss) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Er is een fout opgetreden")
        }
    }
    
    private var accountInfoView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account Informatie")
                .font(.title2)
                .bold()
            
            TextField("Gebruikersnaam", text: $viewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            if !viewModel.username.isEmpty && !viewModel.isValidUsername {
                Text("Gebruikersnaam moet tussen 3 en 20 tekens zijn")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            TextField("Volledige naam", text: $viewModel.fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !viewModel.fullName.isEmpty && !viewModel.isValidFullName {
                Text("Vul je volledige naam in")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var personalInfoView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Persoonlijke Informatie")
                .font(.title2)
                .bold()
            
            DatePicker(
                "Geboortedatum",
                selection: $viewModel.birthDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            
            Picker("Geslacht", selection: $viewModel.gender) {
                ForEach(UserGender.allCases, id: \.self) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            }
            .pickerStyle(.segmented)
            
            Spacer()
        }
        .padding()
    }
    
    private var bodyMeasurementsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Lichaamsmetingen")
                .font(.title2)
                .bold()
            
            HStack {
                TextField("Lengte", text: $viewModel.height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Text("cm")
            }
            
            if !viewModel.height.isEmpty && !viewModel.isValidHeight {
                Text("Voer een geldige lengte in (100-250 cm)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                TextField("Gewicht", text: $viewModel.weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Text("kg")
            }
            
            if !viewModel.weight.isEmpty && !viewModel.isValidWeight {
                Text("Voer een geldig gewicht in (30-300 kg)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if viewModel.isValidHeight && viewModel.isValidWeight,
               let height = Double(viewModel.height),
               let weight = Double(viewModel.weight) {
                let bmi = weight / pow(height/100, 2)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Je BMI: \(String(format: "%.1f", bmi))")
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
    
    private var nutritionGoalsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Voedingsdoelen")
                .font(.title2)
                .bold()
            
            Text("Deze doelen zijn berekend op basis van je gegevens. Je kunt ze aanpassen naar jouw persoonlijke doelen.")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: {
                viewModel.calculateRecommendedCalories()
            }) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text("Bereken aanbevolen doelen")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.bottom)
            
            Group {
                HStack {
                    Text("Dagelijkse calorieën")
                    Spacer()
                    TextField("Calorieën", text: $viewModel.calorieGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                    Text("kcal")
                }
                
                HStack {
                    Text("Eiwitten")
                    Spacer()
                    TextField("Eiwitten", text: $viewModel.proteinGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                    Text("g")
                }
                
                HStack {
                    Text("Koolhydraten")
                    Spacer()
                    TextField("Koolhydraten", text: $viewModel.carbsGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                    Text("g")
                }
                
                HStack {
                    Text("Vetten")
                    Spacer()
                    TextField("Vetten", text: $viewModel.fatGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                    Text("g")
                }
            }
            
            if !viewModel.isValidNutritionGoals {
                Text("Voer geldige waarden in:\n" +
                     "• Calorieën: 1200-5000 kcal\n" +
                     "• Eiwitten: 30-400 g\n" +
                     "• Koolhydraten: 50-600 g\n" +
                     "• Vetten: 20-200 g")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}