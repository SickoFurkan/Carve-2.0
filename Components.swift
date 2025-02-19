import SwiftUI

public struct NavigationBar: View {
    let title: String
    @Binding var selectedDate: Date
    let onMenuTap: () -> Void
    let onProfileTap: () -> Void
    let pageType: NavigationPageType
    @Environment(\.colorScheme) var colorScheme
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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = Date()
                            }
                        }
                    
                    Button(action: { showingCalendarPicker = true }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
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
            VStack(spacing: 8) {
                // Days of the week
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }
                
                // Date circles with swipe gesture
                HStack(spacing: 0) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        DateCircle(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            pageType: pageType
                        )
                        .onTapGesture {
                            withAnimation {
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
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var dateTextColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .primary
        } else {
            return colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.7)
        }
    }
    
    private var circleColor: Color {
        switch pageType {
        case .forkDowns:
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
            
        case .muscleUps:
            return workoutStore.getWorkoutColor(for: date)
        }
    }
    
    private var calorieProgress: Double {
        let calories = nutritionStore.getTotalCaloriesForDate(date)
        let goalCalories = 2000.0 // This should come from user's profile
        return min(Double(calories) / goalCalories, 1.0)
    }
    
    private var indicatorText: String {
        switch pageType {
        case .forkDowns:
            let calories = nutritionStore.getTotalCaloriesForDate(date)
            return calories > 0 ? "\(calories)" : ""
        case .muscleUps:
            let muscleGroups = workoutStore.getMuscleGroups(for: date)
            return muscleGroups.isEmpty ? "" : "\(muscleGroups.count)"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(circleColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                // Date circle
                Circle()
                    .fill(isSelected ? circleColor : Color.clear)
                    .frame(width: 34, height: 34)
                
                // Date text
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .medium : .regular))
                    .foregroundColor(dateTextColor)
            }
            
            if !indicatorText.isEmpty {
                Text(indicatorText)
                    .font(.system(size: 10))
                    .foregroundColor(isToday ? .gray : .gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
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
        ZStack {
            // Background
            AuroraBackground(content: { EmptyView() })
                .ignoresSafeArea()
                .zIndex(0)
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    content
                }
                .padding(.vertical)
            }
            .zIndex(1)
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
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var foodInput: String = ""
    
    let workouts = [
        (name: "Chest", color: Color.red, icon: "figure.strengthtraining.traditional"),
        (name: "Back", color: Color.green, icon: "figure.chin.up"),
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
                                // Handle workout selection
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
                            
                            Text("Add Food")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        
                        TextField("", text: $foodInput)
                            .font(.system(size: 17))
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCamera = true
                        }) {
                            Text("Analyze")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        // Camera View
                        Button(action: {
                            showingCamera = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue)
                                    .frame(height: 60)
                                    .overlay(
                                        HStack(spacing: 12) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                            Text("Take a photo")
                                                .font(.headline)
                                        }
                                        .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            foodInput = "3 bananas, 300gr milkshake"
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(nutritionStore: nutritionStore)
        }
    }
} 
