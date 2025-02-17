import SwiftUI
import PhotosUI

public struct HomePageView: View {
    @StateObject private var viewModel: FoodEntryViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedDate: Date
    @ObservedObject var nutritionStore: NutritionStore
    @State private var foodEntries: [FoodEntry] = []
    @State private var isAnalyzingPhoto = false
    @State private var showCamera = false
    @State private var tempImage: UIImage?
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var userProfile: UserProfile?
    @FocusState private var focusedField: Field?
    
    public init(selectedDate: Binding<Date>, nutritionStore: NutritionStore) {
        self._selectedDate = selectedDate
        self.nutritionStore = nutritionStore
        self._viewModel = StateObject(wrappedValue: FoodEntryViewModel(selectedDate: selectedDate.wrappedValue))
    }
    
    public enum Field {
        case foodName
        case amount
    }
    
    private var dailyGoals: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        if let profile = userProfile {
            return (
                calories: profile.dailyCalorieGoal,
                protein: profile.dailyProteinGoal,
                carbs: profile.dailyCarbsGoal,
                fat: profile.dailyFatGoal
            )
        } else {
            return (
                calories: Configuration.defaultDailyCalories,
                protein: Configuration.defaultProteinGoal,
                carbs: Configuration.defaultCarbsGoal,
                fat: Configuration.defaultFatGoal
            )
        }
    }
    
    private var consumedNutrition: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        var calories = 0
        var protein = 0
        var carbs = 0
        var fat = 0
        
        for entry in foodEntries {
            calories += entry.calories
            protein += entry.protein
            carbs += entry.carbs
            fat += entry.fat
        }
        
        return (calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
    
    private var remainingNutrition: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        let consumed = consumedNutrition
        
        let remainingCalories = dailyGoals.calories - consumed.calories
        let remainingProtein = dailyGoals.protein - consumed.protein
        let remainingCarbs = dailyGoals.carbs - consumed.carbs
        let remainingFat = dailyGoals.fat - consumed.fat
        
        return (
            calories: remainingCalories,
            protein: remainingProtein,
            carbs: remainingCarbs,
            fat: remainingFat
        )
    }
    
    private var progressPercentage: Double {
        let remaining = Double(remainingNutrition.calories)
        let goal = Double(dailyGoals.calories)
        return remaining / goal
    }
    
    // MARK: - Helper Methods
    private func getTextColor() -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    private func getBackgroundOpacity() -> Double {
        colorScheme == .dark ? 0.2 : 0.3
    }
    
    private func getButtonBackground(isAnalyzing: Bool) -> Color {
        isAnalyzing ? .gray : .blue
    }
    
    // MARK: - Food Entry Views
    private var foodEntryTitle: some View {
        Text("Voedsel Invoer")
            .font(.headline)
    }
    
    private var foodNameField: some View {
        TextField("Voedsel naam", text: $viewModel.foodName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($focusedField, equals: .foodName)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .amount
            }
    }
    
    private var amountField: some View {
        TextField("Hoeveelheid in gram", text: $viewModel.foodAmount)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .focused($focusedField, equals: .amount)
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
            }
    }
    
    private var addButton: some View {
        Button(action: {
            focusedField = nil
            Task {
                if let analysis = await viewModel.analyzeFoodEntry() {
                    let entry = FoodEntry(
                        name: viewModel.foodName,
                        amount: Int(viewModel.foodAmount) ?? 0,
                        calories: analysis.calories,
                        protein: analysis.protein,
                        carbs: analysis.carbs,
                        fat: analysis.fat
                    )
                    foodEntries.append(entry)
                    viewModel.clearFields()
                }
            }
        }) {
            Text(viewModel.isAnalyzing ? "Bezig..." : "Handmatig Toevoegen")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(getButtonBackground(isAnalyzing: viewModel.isAnalyzing))
                .cornerRadius(8)
        }
        .disabled(viewModel.isAnalyzing)
    }
    
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            foodNameField
            amountField
            addButton
        }
    }
    
    private var foodEntryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                foodEntryTitle
                manualEntrySection
                Divider()
                    .padding(.vertical, 8)
                photoAnalysisSection
            }
        }
    }
    
    // MARK: - Title View
    private var titleView: some View {
        Text("Dagelijks Overzicht")
            .font(.headline)
            .foregroundColor(getTextColor())
    }
    
    // MARK: - Progress Circle Views
    private var backgroundCircle: some View {
        Circle()
            .stroke(lineWidth: 20)
            .foregroundColor(Color.gray.opacity(getBackgroundOpacity()))
    }
    
    private var progressCircle: some View {
        Circle()
            .trim(from: 0.0, to: progressPercentage)
            .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
            .foregroundColor(.green)
            .rotationEffect(Angle(degrees: 270.0))
    }
    
    private var nutritionInfoView: some View {
        VStack {
            if userProfile == nil {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(height: 50)
            } else {
                Text("\(remainingNutrition.calories)")
                    .font(.title)
                    .bold()
                Text("van \(dailyGoals.calories) kcal over")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var circularProgressChart: some View {
        ZStack {
            backgroundCircle
            progressCircle
            nutritionInfoView
        }
        .frame(height: 200)
        .padding()
    }
    
    private var macrosProgressView: some View {
        HStack(spacing: 20) {
            MacroProgressBar(
                label: "Proteïne",
                current: remainingNutrition.protein,
                goal: dailyGoals.protein,
                unit: "g",
                color: .blue,
                isLoading: userProfile == nil
            )
            
            MacroProgressBar(
                label: "Koolhydraten",
                current: remainingNutrition.carbs,
                goal: dailyGoals.carbs,
                unit: "g",
                color: .orange,
                isLoading: userProfile == nil
            )
            
            MacroProgressBar(
                label: "Vetten",
                current: remainingNutrition.fat,
                goal: dailyGoals.fat,
                unit: "g",
                color: .red,
                isLoading: userProfile == nil
            )
        }
        .padding(.horizontal)
    }
    
    private var dailyProgressCard: some View {
        CardView {
            VStack(spacing: 16) {
                titleView
                circularProgressChart
                macrosProgressView
            }
        }
    }
    
    private var photoAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Foto Analyse")
                .font(.subheadline)
            
            HStack(spacing: 8) {
                PhotosPicker(selection: Binding(
                    get: { nil },
                    set: { newValue in
                        if let newValue {
                            Task {
                                isAnalyzingPhoto = true
                                do {
                                    let data = try await newValue.loadTransferable(type: Data.self)
                                    if let data = data, let image = UIImage(data: data) {
                                        await MainActor.run {
                                            viewModel.setImage(image)
                                        }
                                    }
                                } catch {
                                    print("Error loading image: \(error)")
                                }
                                isAnalyzingPhoto = false
                            }
                        }
                    }
                ), matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Galerij")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isAnalyzingPhoto ? Color.gray : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isAnalyzingPhoto)
                
                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Camera")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            
            // Replace sample images with PhotoGalleryView
            PhotoGalleryView { selectedImage in
                viewModel.setImage(selectedImage)
            }
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                dailyProgressCard
                foodEntryCard
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Gereed") {
                    focusedField = nil
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $tempImage) { capturedImage in
                viewModel.setImage(capturedImage)
            }
        }
        .task {
            await loadUserProfile()
            await loadFoodEntries()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            Task {
                viewModel.updateSelectedDate(newValue)
                await loadFoodEntries()
            }
        }
    }
    
    private func loadUserProfile() async {
        do {
            if let profile = try await firebaseService.getUserProfile() {
                await MainActor.run {
                    self.userProfile = profile
                }
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    private func loadFoodEntries() async {
        do {
            let entries = try await firebaseService.getFoodEntries(for: selectedDate)
            await MainActor.run {
                self.foodEntries = entries
            }
        } catch {
            print("Error loading food entries: \(error)")
        }
    }
}

#Preview {
    HomePageView(
        selectedDate: .constant(Date()),
        nutritionStore: NutritionStore()
    )
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 