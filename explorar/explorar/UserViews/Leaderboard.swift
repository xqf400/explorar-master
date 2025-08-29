//
//  Leaderboard.swift
//  explorar
//
//  Created by Fabian Kuschke on 24.07.25.
//

import SwiftUI
import TelemetryClient

class LeaderboardViewModel: ObservableObject {
    @Environment(\.colorScheme) var colorScheme
    @Published var topUsers: [FirestoreService.LeaderboardEntry] = []
    @Published var errorMessage: String?
    
    func loadTopUsers() {
        FirestoreService.shared.fetchMyTopFriendsAndMe { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    self.topUsers = users
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
func normalizeUser(_ str: String) -> String {
    let lowered = str.lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: .diacriticInsensitive, locale: .current)

    let allowed = CharacterSet.alphanumerics
    let filtered = lowered.unicodeScalars.filter { allowed.contains($0) }
    return String(String.UnicodeScalarView(filtered))
}

struct LeaderboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LeaderboardViewModel()
    @ObservedObject var userFire = UserFire.shared
    @Environment(\.dismiss) var dismiss
    @State var friendName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        // backgroundGradient just works with GeometryReader here
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack {
                    
                    if userFire.userFirebase?.friendsIds.count ?? 0 > 0 {
                        if let error = viewModel.errorMessage {
                            Text("Error: \(error)")
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.red)
                        } else if viewModel.topUsers.isEmpty {
                            ProgressView("Loading...")
                        } else {
                            VStack() {
                                    Text("🏆 Top 5 Friends")
                                    .minimumScaleFactor(0.5)
                                        .font(.title)
                                        .padding(.bottom, 10)
                                ForEach(Array(viewModel.topUsers.enumerated()), id: \.element.id) { index, user in
                                    HStack {
                                        Spacer().frame(width: 20)
                                        Group {
                                            if index == 0 {
                                                Image(systemName: "crown.fill")
                                                    .foregroundColor(.yellow)
                                            } else if index == 1 {
                                                Image(systemName: "medal.fill")
                                                    .foregroundColor(.gray)
                                            } else if index == 2 {
                                                Image(systemName: "medal")
                                                    .foregroundColor(.brown)
                                            } else {
                                                Image(systemName: "circle.fill")
                                                    .opacity(0)
                                            }
                                        }
                                        .frame(width: 24)
                                        
                                        Text(user.id == userFire.userFirebase?.uid ? "\(user.name) (You⭐️)" : user.name)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text("\(user.points) points")
                                            .foregroundColor(.blue)
                                        Spacer().frame(width: 20)
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                        .overlay(Color.orange)
                                }
                            }
                            .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
                            .padding(.horizontal, 16)
                        }
                    } else {
                        Text("Noch keine Freunde hinzugefügt!")
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 10) {
                        HStack {
                            TextField("Username", text: $friendName)
                                .placeholder(when: friendName.isEmpty) {
                                    Text("Username")
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.blue)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                                .submitLabel(.done)
                                .onSubmit {
                                    FirestoreService.shared.searchAndAddFriend(username: normalizeUser(friendName)) { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success(let username):
                                                alertMessage = "Friend \(username) added"
                                                showingAlert = true
                                                viewModel.loadTopUsers()
                                            case .failure(let error):
                                                alertMessage = error.localizedDescription
                                                showingAlert = true
                                            }
                                        }
                                    }
                                }
                        }
                        HStack {
                            Button {
                                FirestoreService.shared.searchAndAddFriend(username: friendName) { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(let username):
                                            alertMessage = "Friend \(username) added"
                                            showingAlert = true
                                            viewModel.loadTopUsers()
                                            friendName = ""
                                            UIApplication.shared.dismissKeyboard()
                                        case .failure(let error):
                                            alertMessage = error.localizedDescription
                                            showingAlert = true
                                        }
                                    }
                                }
                            } label: {
                                Text("Add friend")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(
                                        Color(UIColor.secondarySystemBackground)
                                    )
                            }
                        }
                        .frame(height: 60)
                        .frame(minWidth: 300)
                        .background(Color.green)
                        .cornerRadius(30)
                        .padding(.bottom, 10)
                    }
                    .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
                    .padding(.horizontal, 16)
                    
                    Spacer().frame(height: 20)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .onAppear {
                viewModel.loadTopUsers()
                TelemetryDeck.signal("Leaderboard_Loaded")
            }
        }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
