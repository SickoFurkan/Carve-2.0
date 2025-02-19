import SwiftUI

public struct NavigationBar: View {
    let title: String
    @Binding var selectedDate: Date
    let onMenuTap: () -> Void
    let onProfileTap: () -> Void
    let pageType: NavigationPageType
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var nutritionStore: NutritionStore
    @State private var showingCalendarPicker = false
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    
    private let calendar = Calendar.current
    
    private var weekDays: [String] {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
    
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        
        // Get the start of the week (Monday) for the selected date
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (currentWeekday + 5) % 7
        
        // Create date components for subtraction
        var dateComponents = DateComponents()
        dateComponents.day = -daysToSubtract
        
        // Get Monday by subtracting the calculated days
        guard let monday = calendar.date(byAdding: dateComponents, to: selectedDate) else {
            return []
        }
        
        // Generate dates for the week starting from Monday
        return (0...6).compactMap { day in
            var components = DateComponents()
            components.day = day
            return calendar.date(byAdding: components, to: monday)
        }
    }
    
    private func moveWeek(by numberOfWeeks: Int) {
        guard let newDate = calendar.date(byAdding: .weekOfYear, value: numberOfWeeks, to: selectedDate) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = newDate
        }
    }
    
    public init(
        title: String,
        selectedDate: Binding<Date>,
        pageType: NavigationPageType,
        onMenuTap: @escaping () -> Void,
        onProfileTap: @escaping () -> Void
    ) {
        self.title = title
        self._selectedDate = selectedDate
        self.pageType = pageType
        self.onMenuTap = onMenuTap
        self.onProfileTap = onProfileTap
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Section
            HStack {
                Button(action: onMenuTap) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .onTapGesture {
                            showingCalendarPicker = true
                        }
                }
                
                Spacer()
                
                Button(action: onProfileTap) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            // Date Selection Section
            VStack(spacing: 0) {
                // Days of the week with background highlight
                HStack(spacing: 0) {
                    ForEach(Array(zip(weekDays.indices, weekDays)), id: \.0) { index, day in
                        let isSelected = calendar.isDate(currentWeekDates[index], inSameDayAs: selectedDate)
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 50, height: 30)
                            }
                            
                            Text(day)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(isSelected ? .primary : .gray)
                        }
                    }
                }
                
                // Date circles with swipe gesture
                HStack(spacing: 0) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 50)
                                    .frame(height: 70)
                                    .offset(y: -2)
                            }
                            
                            DateCircle(
                                date: date,
                                isSelected: isSelected,
                                pageType: pageType
                            )
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold {
                                moveWeek(by: -1)
                            } else if value.translation.width < -threshold {
                                moveWeek(by: 1)
                            }
                        }
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .sheet(isPresented: $showingCalendarPicker) {
            MonthCalendarView(selectedDate: $selectedDate, isPresented: $showingCalendarPicker, pageType: pageType)
                .environmentObject(workoutStore)
                .environmentObject(nutritionStore)
        }
    }
}

public enum NavigationPageType {
    case forkDowns
    case muscleUps
}

private struct DateCircle: View {
    let date: Date
    let isSelected: Bool
    let pageType: NavigationPageType
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var isAnimating = false
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var dateTextColor: Color {
        if isSelected {
            return .primary
        } else if isToday {
            return .primary
        } else {
            return colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.7)
        }
    }
    
    private var calorieRingColor: Color {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000 // This should come from user's profile
        
        if calories == 0 {
            return .gray.opacity(0.3)
        } else if calories < Int(Double(goalCalories) * 0.5) {
            return .blue.opacity(0.3)
        } else if calories < Int(Double(goalCalories) * 0.8) {
            return .blue.opacity(0.6)
        } else if calories <= goalCalories {
            return .blue
        } else {
            return .red
        }
    }
    
    private var muscleGroupColor: Color {
        let muscleGroups = workoutStore.getMuscleGroups(for: date)
        if muscleGroups.isEmpty {
            return .clear
        } else if muscleGroups.count == 1 {
            return muscleGroups[0].color
        } else {
            // For multiple muscle groups, create a gradient or blend
            return .blue // You can implement a more sophisticated blending here
        }
    }
    
    private var calorieProgress: Double {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000.0 // This should come from user's profile
        return min(Double(calories) / goalCalories, 1.0)
    }
    
    private var indicatorText: String {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000 // This should come from user's profile
        let remaining = goalCalories - calories
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        let formattedRemaining = numberFormatter.string(from: NSNumber(value: abs(remaining))) ?? "\(abs(remaining))"
        return remaining >= 0 ? formattedRemaining : "-\(formattedRemaining)"
    }
    
    private var indicatorColor: Color {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000 // This should come from user's profile
        let remaining = goalCalories - calories
        return remaining < 0 ? .red : .gray
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Date circle and progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                // Progress ring for calories
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(calorieRingColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                // Inner circle for muscle groups
                Circle()
                    .fill(muscleGroupColor)
                    .frame(width: 34, height: 34)
                
                // Date text
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .medium : .regular))
                    .foregroundColor(dateTextColor)
            }
            
            // Calories text
            Text(indicatorText)
                .font(.system(size: 10))
                .foregroundColor(indicatorColor)
                .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Preview
struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBar(
            title: "Carve",
            selectedDate: .constant(Date()),
            pageType: .forkDowns,
            onMenuTap: {},
            onProfileTap: {}
        )
        .environmentObject(WorkoutStore())
        .environmentObject(NutritionStore())
    }
}

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

public struct SettingsRow: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    @Binding var value: String
    let unit: String
    
    public init(label: String, value: Binding<String>, unit: String) {
        self.label = label
        self._value = value
        self.unit = unit
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Spacer()
            TextField("", text: $value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 60)
            Text(unit)
                .foregroundColor(.gray)
        }
    }
}

public struct SettingsButton: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    
    public init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }
    
    public var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(title)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}

public struct CircularProgressView: View {
    let progress: Double
    
    public init(progress: Double) {
        self.progress = progress
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(.green)
                .rotationEffect(Angle(degrees: 270.0))
        }
    }
}

public struct ProgressStat: View {
    let value: Int
    let target: Int
    let unit: String
    let color: Color
    
    public init(value: Int, target: Int, unit: String, color: Color) {
        self.value = value
        self.target = target
        self.unit = unit
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)/\(target)\(unit)")
                .font(.caption)
                .foregroundColor(.gray)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 6)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(target), height: 6)
                        .foregroundColor(color)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
    }
}

public struct MacroProgressBar: View {
    let label: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    let isLoading: Bool
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            if isLoading {
                ProgressView()
                    .frame(height: 20)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(color.opacity(0.2))
                                .frame(width: geometry.size.width, height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(color)
                                .frame(width: min(CGFloat(current) / CGFloat(goal) * geometry.size.width, geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(current)/\(goal)\(unit)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AddActionSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    let onWorkoutTap: () -> Void
    let onCameraTap: () -> Void
    let onLibraryTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Action sheet content
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray)
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                
                HStack(spacing: 20) {
                    // Left section - Workout
                    VStack {
                        Button(action: onWorkoutTap) {
                            VStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 24))
                                Text("Add Workout")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right section - Food
                    VStack(spacing: 12) {
                        Button(action: onCameraTap) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Camera")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: onLibraryTap) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24))
                                Text("Library")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .transition(.move(edge: .bottom))
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

public struct StandardPageLayout: ViewModifier {
    public func body(content: Content) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                content
            }
            .padding(.vertical)
        }
    }
}

extension View {
    public func standardPageLayout() -> some View {
        modifier(StandardPageLayout())
    }
}

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let pageType: NavigationPageType
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var nutritionStore: NutritionStore
    private let calendar = Calendar.current
    private let daysInWeek = 7
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var monthDates: [Date] {
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        let startOfMonth = calendar.startOfDay(for: interval.start)
        let startWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = (startWeekday + 5) % 7 // Adjust to start from Monday
        
        var dates: [Date] = []
        
        // Add dates from previous month
        if offsetDays > 0 {
            for day in (1...offsetDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -day, to: startOfMonth) {
                    dates.append(date)
                }
            }
        }
        
        // Add dates from current month
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                dates.append(date)
            }
        }
        
        // Add dates from next month to complete the grid
        let remainingDays = (daysInWeek - (dates.count % daysInWeek)) % daysInWeek
        if remainingDays > 0 {
            for day in 0..<remainingDays {
                if let date = calendar.date(byAdding: .day, value: days + day, to: startOfMonth) {
                    dates.append(date)
                }
            }
        }
        
        return dates
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Month and Year header
                Text(selectedDate.formatted(.dateTime.month().year()))
                    .font(.title2.bold())
                    .padding(.top)
                
                // Weekday headers
                HStack {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(monthDates, id: \.self) { date in
                        DateCircle(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            pageType: pageType
                        )
                        .onTapGesture {
                            selectedDate = date
                            isPresented = false
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private var weekDays: [String] {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
}

struct WorkoutCameraSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var nutritionStore: NutritionStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var foodInput: String = ""
    @State private var selectedWorkout: (name: String, color: Color)? = nil
    @State private var isAnalyzing = false
    @State private var throwPosition: CGSize = .zero
    @Namespace private var animation
    
    let workouts = [
        (name: "Chest", color: Color.red, icon: "figure.strengthtraining.traditional"),
        (name: "Back", color: Color.yellow, icon: "figure.chin.up"),
        (name: "Legs", color: Color.blue, icon: "figure.walk"),
        (name: "Cardio", color: Color.green, icon: "heart.slash.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Material.ultraThinMaterial)
                    .frame(height: UIScreen.main.bounds.height * 0.85)
                
                VStack(spacing: 20) {
                    // Workout Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(workouts.indices, id: \.self) { index in
                            let workout = workouts[index]
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedWorkout = (workout.name, workout.color)
                                    throwPosition = CGSize(width: 0, height: -UIScreen.main.bounds.height * 0.4)
                                }

                                // Add workout to store with appropriate muscle groups
                                let muscleGroup: MuscleGroup
                                switch workout.name {
                                case "Chest":
                                    muscleGroup = .chest
                                case "Back":
                                    muscleGroup = .back
                                case "Legs":
                                    muscleGroup = .legs
                                default:
                                    muscleGroup = .core // Default case
                                }
                                
                                workoutStore.addWorkout(
                                    muscleGroups: [muscleGroup],
                                    name: workout.name,
                                    duration: 0,
                                    exercises: [],
                                    for: Date()
                                )

                                // Dismiss after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    isPresented = false
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(workout.color.opacity(0.1))
                                    .frame(height: 100)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: workout.icon)
                                                .font(.system(size: 28))
                                                .foregroundColor(workout.color)
                                            Text(workout.name)
                                                .font(.title3)
                                                .foregroundColor(workout.color)
                                                .fontWeight(.semibold)
                                        }
                                    )
                                    .matchedGeometryEffect(id: workout.name, in: animation)
                                    .offset(selectedWorkout?.name == workout.name ? throwPosition : .zero)
                                    .scaleEffect(selectedWorkout?.name == workout.name ? 0.7 : 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Add Food Section with lines
                    VStack(spacing: 16) {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                            
                            Text("Add")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("Food")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            TextField("A banana and a small milkshake", text: $foodInput)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(15)
                            
                            Button(action: {
                                analyzeFoodAndAnimate()
                            }) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Camera View
                        if showingCamera {
                            CameraView(nutritionStore: nutritionStore)
                                .frame(height: 250)
                                .cornerRadius(12)
                                .overlay(alignment: .topTrailing) {
                                    Button(action: {
                                        showingCamera = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                    .padding(.top, 8)
                                    .padding(.trailing, 8)
                                }
                                .padding([.horizontal, .bottom])
                        } else {
                            Button(action: {
                                showingCamera = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                    Text("Take Photo of Food")
                                        .font(.headline)
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding([.horizontal, .bottom])
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            showingCamera = true // Automatically show camera when sheet appears
        }
    }
    
    private func analyzeFoodAndAnimate() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isAnalyzing = true
            throwPosition = CGSize(width: 0, height: -UIScreen.main.bounds.height * 0.4)
        }
        
        // Simulate analysis time and add to meals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString = timeFormatter.string(from: Date())
            
            let meal = Meal(
                id: UUID(),
                name: foodInput,
                calories: 300, // Example values
                protein: 20,
                carbs: 40,
                fat: 10,
                time: timeString
            )
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                nutritionStore.addMeal(meal, for: Date())
            }
            
            // Dismiss sheet after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPresented = false
            }
        }
    }
}

// Remove FoodEntriesList struct from here since it's in its own file

// ... existing code ...
