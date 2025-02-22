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
    @Binding var showingWorkoutSheet: Bool
    let items: [(image: String, title: String)]
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
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
                    lightHaptic.impactOccurred(intensity: 0.3)
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
                TranslucentBackground()
                
                // Bottom border line
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { _ in
                    lightHaptic.impactOccurred(intensity: 0.2)
                }
                .onEnded { gesture in
                    if gesture.translation.height < -50 { // Swipe up
                        lightHaptic.impactOccurred(intensity: 0.3)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingWorkoutSheet = true
                        }
                    } else if abs(gesture.translation.width) > 50 { // Horizontal swipe
                        lightHaptic.impactOccurred(intensity: 0.3)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if gesture.translation.width > 0 && selectedTab > 0 {
                                // Swipe right
                                selectedTab -= 1
                            } else if gesture.translation.width < 0 && selectedTab < items.count - 1 {
                                // Swipe left
                                selectedTab += 1
                            }
                        }
                    }
                }
        )
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
    @State private var selectedTab = 0 // Home tab (leftmost)
    @State private var selectedDate = Date()
    @State private var showingSideMenu = false
    @State private var selectedTestPage: Int? = nil
    @State private var showingAddSheet = false
    @State private var showingCamera = false
    @State private var showingWorkoutSheet = false
    @State private var showingTrainerChat = false
    
    // Update store references to use explicit type declaration
    @StateObject private var nutritionStore: NutritionStore = .shared
    @StateObject private var workoutStore: WorkoutStore = .shared
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var keyboardHandler = KeyboardHandler()
    
    // Update haptic feedback generator
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
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
                        .environmentObject(workoutStore)
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
            // Single persistent aurora background
            AuroraBackground(content: { EmptyView() })
                .ignoresSafeArea()
                .zIndex(0)
            
            // Navigation Bar
            NavigationBar(
                title: "Carve",
                selectedDate: $selectedDate,
                pageType: selectedTab == 0 ? .muscleUps : .forkDowns,
                onTrainerTap: {
                    withAnimation(.easeInOut) {
                        showingTrainerChat = true
                    }
                },
                onProfileTap: {
                    showingProfile = true
                }
            )
            .environmentObject(nutritionStore)
            .environmentObject(workoutStore)
            .zIndex(2)
            
            TabView(selection: $selectedTab) {
                HomePageView(selectedDate: $selectedDate, nutritionStore: nutritionStore)
                    .tag(0)
                    .ignoresSafeArea(.container, edges: [.bottom])
                
                MuscleUpsView(selectedDate: $selectedDate)
                    .tag(1)
                    .ignoresSafeArea(.container, edges: [.bottom])
                    .environmentObject(workoutStore)
                
                ForkDownsView(selectedDate: $selectedDate, nutritionStore: nutritionStore)
                    .tag(2)
                    .ignoresSafeArea(.container, edges: [.bottom])
                
                KnowledgeView()
                    .tag(3)
                    .ignoresSafeArea(.container, edges: [.bottom])
            }
            .onChange(of: selectedTab) { newValue in
                lightHaptic.impactOccurred(intensity: 0.2)
            }
            .padding(.top, 130)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.container, edges: [.bottom])
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .interactiveDismissDisabled()
            .zIndex(1)
            
            // Bottom Tab Bar and Plus Button
            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showingWorkoutSheet: $showingWorkoutSheet,
                    items: [
                        (image: "house.fill", title: "Home"),
                        (image: "figure.strengthtraining.traditional", title: "Muscle Ups"),
                        (image: "fork.knife", title: "Fork Downs"),
                        (image: "book.fill", title: "Knowledge")
                    ]
                )
            }
            .ignoresSafeArea(.keyboard)
            .zIndex(3)
        }
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                ProfileView()
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(nutritionStore: nutritionStore)
                .environmentObject(CameraManager())
        }
        .sheet(isPresented: $showingWorkoutSheet) {
            AddWorkoutFoodSheet(isPresented: $showingWorkoutSheet, nutritionStore: nutritionStore)
                .environmentObject(workoutStore)
                .presentationDetents([.large])
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showingTrainerChat) {
            TrainerChatView(nutritionStore: nutritionStore, workoutStore: workoutStore)
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
