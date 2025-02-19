//
//  ContentView.swift
//  Carve
//
//  Created by Furkan Çeliker on 07/02/2025.
//

import SwiftUI
import PhotosUI
import Combine

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let items: [(image: String, title: String)]
    
    var body: some View {
        HStack {
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                TabItemView(
                    isSelected: selectedTab == index,
                    imageName: item.image,
                    title: item.title
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
                
                if index != items.count - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Blur effect
                TranslucentBackground()
                
                // Top border line
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: 0)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct TabItemView: View {
    let isSelected: Bool
    let imageName: String
    let title: String
    
    @State private var bounceScale: CGFloat = 1.0
    
    var iconColor: Color {
        switch title {
        case "Muscle Ups":
            return .red
        case "Fork Downs":
            return .orange
        case "Knowledge":
            return .blue
        case "Live":
            return .green
        default:
            return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle for selected state
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .scaleEffect(isSelected ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                Image(systemName: imageName)
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? iconColor : .gray.opacity(0.8))
                    .scaleEffect(bounceScale)
                    .frame(width: 48, height: 48)
            }
            
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? iconColor : .gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isSelected) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        bounceScale = 1.0
                    }
                }
            }
        }
    }
}

struct TranslucentBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if colorScheme == .dark {
            Color(UIColor.systemBackground)
                .opacity(0.9)
                .background(.ultraThinMaterial)
        } else {
            Color(UIColor.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        }
    }
}

struct ContentView: View {
    @State private var showingProfile = false
    @State private var showingProfileSetup = false
    @State private var selectedTab = 1
    @State private var selectedDate = Date()
    @State private var showingSideMenu = false
    @State private var selectedTestPage: Int? = nil
    @State private var showingAddSheet = false
    @State private var showingCamera = false
    @State private var showingWorkoutSheet = false
    @StateObject private var nutritionStore = NutritionStore()
    @StateObject private var workoutStore: WorkoutStore = {
        let store = WorkoutStore()
        return store
    }()
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var keyboardHandler = KeyboardHandler()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if firebaseService.isAuthenticated {
                        ZStack {
                            if let pageNumber = selectedTestPage {
                                TestPageView(pageNumber: pageNumber)
                            } else {
                                mainView
                                    .task {
                                        await checkProfileStatus()
                                    }
                                    .fullScreenCover(isPresented: $showingProfileSetup) {
                                        ProfileSetupView()
                                    }
                            }
                            
                            SideMenuView(isShowing: $showingSideMenu, selectedPage: $selectedTestPage)
                        }
                    } else {
                        WelcomeView()
                    }
                }
                .preferredColorScheme(.light)
                .ignoresSafeArea(.keyboard)
                .onAppear {
                    UIApplication.shared.hideKeyboardWhenTappedAround()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .inactive {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .padding(.bottom, keyboardHandler.keyboardHeight)
                .animation(.easeOut(duration: 0.16), value: keyboardHandler.keyboardHeight)
                
                // Add Action Sheet
                if showingAddSheet {
                    AddActionSheet(
                        isPresented: $showingAddSheet,
                        onWorkoutTap: {
                            // Handle workout tap
                            showingAddSheet = false
                        },
                        onCameraTap: {
                            showingCamera = true
                            showingAddSheet = false
                        },
                        onLibraryTap: {
                            // Handle library tap
                            showingAddSheet = false
                        }
                    )
                }
            }
        }
    }
    
    private func checkProfileStatus() async {
        do {
            if let profile = try await firebaseService.getUserProfile() {
                showingProfileSetup = profile.fullName.isEmpty || profile.height <= 0 || profile.weight <= 0
            } else {
                showingProfileSetup = true
            }
        } catch {
            print("Error checking profile status: \(error)")
            showingProfileSetup = true
        }
    }
    
    var mainView: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                MuscleUpsView(selectedDate: $selectedDate)
                    .tag(0)
                    .ignoresSafeArea(.container, edges: .bottom)
                
                HomePageView(selectedDate: $selectedDate, nutritionStore: nutritionStore)
                    .tag(1)
                    .ignoresSafeArea(.container, edges: .bottom)
                
                KnowledgeView()
                    .tag(2)
                    .ignoresSafeArea(.container, edges: .bottom)
                
                LiveView()
                    .tag(3)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .padding(.top, 140)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.container, edges: .bottom)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .overlay(
                VStack {
                    Spacer()
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        items: [
                            ("figure.strengthtraining.traditional", "Muscle Ups"),
                            ("fork.knife", "Fork Downs"),
                            ("book.fill", "Knowledge"),
                            ("person.2.fill", "Live")
                        ]
                    )
                }
            )
            .overlay(
                // Plus button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingWorkoutSheet = true
                    }
                }) {
                    ZStack {
                        // Main button background
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue,
                                        Color.blue.opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // Plus icon
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showingWorkoutSheet ? 0.9 : 1.0)
                }
                .padding(.bottom, 90)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingWorkoutSheet),
                alignment: .bottom
            )
            
            // Navigation Bar
            NavigationBar(
                title: "Carve",
                selectedDate: $selectedDate,
                pageType: selectedTab == 0 ? .muscleUps : .forkDowns,
                onMenuTap: {
                    withAnimation(.easeInOut) {
                        showingSideMenu = true
                    }
                },
                onProfileTap: {
                    showingProfile = true
                }
            )
            .environmentObject(nutritionStore)
            .environmentObject(workoutStore)
            .sheet(isPresented: $showingProfile) {
                NavigationView {
                    ProfileView()
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(nutritionStore: nutritionStore)
            }
            .sheet(isPresented: $showingWorkoutSheet) {
                WorkoutCameraSheet(isPresented: $showingWorkoutSheet, nutritionStore: nutritionStore)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.85)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

class KeyboardHandler: ObservableObject {
    @Published private(set) var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .map { $0.height }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
            }
            .store(in: &cancellables)
    }
}

extension UIApplication {
    func hideKeyboardWhenTappedAround() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = nil
        window.addGestureRecognizer(tapGesture)
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseService.shared)
}
