//
//  ContentView.swift
//  Carve
//
//  Created by Furkan Çeliker on 07/02/2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var showingProfile = false
    @State private var showingProfileSetup = false
    @State private var selectedTab = 1  // Set to 1 for Fork Downs tab
    @State private var selectedDate = Date()
    @State private var showingSideMenu = false
    @State private var selectedTestPage: Int? = nil
    @StateObject private var nutritionStore = NutritionStore()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var firebaseService: FirebaseService
    
    var body: some View {
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
                    .tabItem {
                        Label("Muscle Ups", systemImage: "figure.strengthtraining.traditional")
                    }
                    .tag(0)
                
                HomePageView(selectedDate: $selectedDate, nutritionStore: nutritionStore)
                    .tabItem {
                        Label("Fork Downs", systemImage: "fork.knife")
                    }
                    .tag(1)
                
                LiveView()
                    .tabItem {
                        Label("Live", systemImage: "person.2.fill")
                    }
                    .tag(2)
            }
            .padding(.top, 128) // Increased padding for the larger NavigationBar
            
            // Custom Navigation Bar
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            showingSideMenu = true
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .padding(.leading)
                    
                    NavigationBar(
                        title: "Carve",
                        subtitle: formattedDate(from: selectedDate),
                        selectedDate: $selectedDate,
                        action: { showingProfile = true }
                    )
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingProfile) {
                NavigationView {
                    ProfileView()
                }
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

#Preview {
    ContentView()
        .environmentObject(FirebaseService.shared)
}
