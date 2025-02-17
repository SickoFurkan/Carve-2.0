import SwiftUI
import Foundation

struct LiveView: View {
    @StateObject private var viewModel = LiveViewModel()
    @State private var searchText = ""
    @State private var showingFriendsList = false
    @State private var showingMenu = false
    @State private var showingSuggestions = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Menu and Search Bar
                HStack {
                    Button(action: {
                        showingMenu = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .confirmationDialog("Menu", isPresented: $showingMenu) {
                        Button("Suggesties") {
                            showingSuggestions = true
                        }
                        // Voeg hier meer menu-items toe
                    }
                    
                    TextField("Zoek vrienden op gebruikersnaam", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .onChange(of: searchText) { oldValue, newValue in
                            viewModel.searchUsers(query: newValue)
                        }
                }
                .padding(.horizontal)
                
                // Friends List Button
                Button(action: {
                    showingFriendsList = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Vriendenlijst")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if !searchText.isEmpty {
                    // Search Results
                    ForEach(viewModel.searchResults) { user in
                        UserCardView(user: user) {
                            viewModel.sendFriendRequest(to: user)
                        }
                    }
                } else {
                    // Friends Feed
                    if viewModel.friends.isEmpty {
                        Text("Nog geen vrienden toegevoegd")
                            .foregroundColor(.gray)
                            .italic()
                            .padding()
                    } else {
                        ForEach(viewModel.friends) { friend in
                            FriendCardView(friend: friend)
                        }
                    }
                }
            }
            .padding(.top)
        }
        .refreshable {
            await viewModel.loadFriends()
        }
        .sheet(isPresented: $showingFriendsList) {
            FriendsListView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadFriends()
        }
    }
}

struct UserCardView: View {
    let user: UserProfile
    let action: () -> Void
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(user.fullName)
                            .font(.headline)
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: action) {
                        Text("Toevoegen")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct FriendCardView: View {
    let friend: UserProfile
    
    private var dailyProgress: Double {
        if let entries = friend.getEntries(for: Date()) {
            return Double(entries.totals.calories) / Double(friend.dailyCalorieGoal)
        }
        return 0.0
    }
    
    var body: some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(friend.fullName)
                            .font(.headline)
                        Text("@\(friend.username)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                        
                        Circle()
                            .trim(from: 0.0, to: dailyProgress)
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.green)
                            .rotationEffect(Angle(degrees: 270.0))
                    }
                    .frame(width: 50, height: 50)
                }
                
                // Macro Progress
                if let entries = friend.getEntries(for: Date()) {
                    VStack(spacing: 8) {
                        MacroProgressRow(
                            label: "Proteïne",
                            consumed: entries.totals.protein,
                            goal: friend.dailyProteinGoal,
                            unit: "g",
                            color: .blue
                        )
                        
                        MacroProgressRow(
                            label: "Koolhydraten",
                            consumed: entries.totals.carbs,
                            goal: friend.dailyCarbsGoal,
                            unit: "g",
                            color: .orange
                        )
                        
                        MacroProgressRow(
                            label: "Vetten",
                            consumed: entries.totals.fat,
                            goal: friend.dailyFatGoal,
                            unit: "g",
                            color: .red
                        )
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct FriendsListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LiveViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section("Vriendschapsverzoeken") {
                    ForEach(viewModel.friendRequests) { request in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(request.fullName)
                                    .font(.headline)
                                Text("@\(request.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    Task {
                                        await viewModel.acceptFriendRequest(from: request)
                                    }
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                
                                Button(action: {
                                    Task {
                                        await viewModel.declineFriendRequest(from: request)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                Section("Vrienden") {
                    ForEach(viewModel.friends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.fullName)
                                    .font(.headline)
                                Text("@\(friend.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await viewModel.removeFriend(friend)
                                }
                            }) {
                                Image(systemName: "person.badge.minus")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vrienden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gereed") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LiveView()
} 