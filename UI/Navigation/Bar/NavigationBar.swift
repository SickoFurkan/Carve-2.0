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
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
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
    
    private let calendar = Calendar.current
    
    private var weekDays: [String] {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
    
    // Break down the complex body property into smaller views
    private var topSection: some View {
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
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private var dateSelectionSection: some View {
        VStack(spacing: 2) {
            // Days of the week with background highlight
            HStack(spacing: 0) {
                ForEach(Array(zip(weekDays.indices, weekDays)), id: \.0) { index, day in
                    let isSelected = calendar.isDate(currentWeekDates[index], inSameDayAs: selectedDate)
                    let isToday = calendar.isDate(currentWeekDates[index], inSameDayAs: Date())
                    WeekDayView(day: day, isSelected: isSelected, isToday: isToday)
                }
            }
            
            // Date circles with swipe gesture
            HStack(spacing: 0) {
                ForEach(currentWeekDates, id: \.self) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    DateSelectionCell(date: date, isSelected: isSelected, pageType: pageType)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                                lightHaptic.impactOccurred(intensity: 0.2)
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
                            lightHaptic.impactOccurred(intensity: 0.2)
                        } else if value.translation.width < -threshold {
                            moveWeek(by: 1)
                            lightHaptic.impactOccurred(intensity: 0.2)
                        }
                    }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            topSection
            dateSelectionSection
        }
        .sheet(isPresented: $showingCalendarPicker) {
            MonthCalendarView(selectedDate: $selectedDate, isPresented: $showingCalendarPicker, pageType: pageType)
                .environmentObject(workoutStore)
                .environmentObject(nutritionStore)
        }
    }
    
    // Helper Views
    private struct WeekDayView: View {
        let day: String
        let isSelected: Bool
        let isToday: Bool
        
        var body: some View {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 24)
                        .animation(.none, value: isSelected)
                        .clipShape(
                            RoundedCorner(
                                radius: 12,
                                corners: [.topLeft, .topRight]
                            )
                        )
                }
                
                Text(day)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(isToday ? .red : (isSelected ? .primary : .gray))
                    .animation(.none, value: isSelected)
            }
        }
    }
    
    private struct DateSelectionCell: View {
        let date: Date
        let isSelected: Bool
        let pageType: NavigationPageType
        
        var body: some View {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50)
                        .frame(height: 50)
                        .offset(y: -2)
                        .clipShape(
                            RoundedCorner(
                                radius: 12,
                                corners: [.bottomLeft, .bottomRight]
                            )
                        )
                }
                
                DateCircle(
                    date: date,
                    isSelected: isSelected,
                    pageType: pageType
                )
            }
        }
    }
    
    // Helper methods
    private func moveWeek(by numberOfWeeks: Int) {
        guard let newDate = calendar.date(byAdding: .weekOfYear, value: numberOfWeeks, to: selectedDate) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = newDate
        }
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
} 