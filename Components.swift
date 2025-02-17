import SwiftUI

public struct NavigationBar: View {
    let title: String
    let subtitle: String?
    let action: () -> Void
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDatePicker = false
    
    public init(title: String, subtitle: String?, selectedDate: Binding<Date>, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self._selectedDate = selectedDate
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 40)
            
            HStack {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Button(action: action) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            Button(action: { showingDatePicker = true }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(subtitle ?? "")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(isPresented: $showingDatePicker, selectedDate: $selectedDate)
            }
            
            Text("Project by Furkan Çeliker")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.bottom, 4)
            
            HStack {
                Button(action: { 
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: { 
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
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
