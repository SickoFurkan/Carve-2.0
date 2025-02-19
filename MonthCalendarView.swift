import SwiftUI

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
                Text(selectedDate.formatted(.dateTime.month().year()))
                    .font(.title2.bold())
                    .padding(.top)
                
                weekDaysHeader
                
                calendarGrid
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private var weekDaysHeader: some View {
        HStack {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var calendarGrid: some View {
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
    }
    
    private var weekDays: [String] {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
} 