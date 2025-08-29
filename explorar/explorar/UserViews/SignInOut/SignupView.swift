//
//  SignUpView.swift
//  explorar
//
//  Created by Fabian Kuschke on 18.07.25.
//

import SwiftUI
import Combine
import Drops

private enum FocusableField: Hashable {
    case email
    case password
    case confirmPassword
}

struct SignupView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthenticationViewModel
    //@Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @FocusState private var focus: FocusableField?
    
    private func signUpWithEmailPassword() {
        Task {
            if await viewModel.signUpWithEmailPassword(userName: newUsername) == true {
                FirestoreService.shared.checkIfUserExists { result in
                    switch result {
                    case .success(let exists):
                        if !exists {
                            print("User does NOT exist-> add to db")
                            FirestoreService.shared.createDatabaseUser { result in
                                FirestoreService.shared.getUser { result in
                                    print("got user")
                                }
                            }
                        } else {
                            print("User exisits in Firestore")
                        }
                    case .failure(let error):
                        print("Error checking user: \(error.localizedDescription)")
                        Drops.show(Drop(title: "Error checking user: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .foregroundColor(.white)
            Spacer()
            VStack {
                Text("Sign up")
                    .minimumScaleFactor(0.5)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    Image(systemName: "person")
                    TextField("Username", text: $newUsername)
                        .textInputAutocapitalization(.never)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .disableAutocorrection(true)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            self.focus = .email
                        }
                }
                .padding(.vertical, 6)
                .background(Divider(), alignment: .bottom)
                .padding(.bottom, 4)
                HStack {
                    Image(systemName: "at")
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .focused($focus, equals: .email)
                        .disabled(newUsername.isEmpty)
                        .opacity(newUsername.isEmpty ? 0.5 : 1.0)
                        .submitLabel(.next)
                        .onSubmit {
                            self.focus = .password
                        }
                }
                .padding(.vertical, 6)
                .background(Divider(), alignment: .bottom)
                .padding(.bottom, 4)
                
                HStack {
                    Image(systemName: "lock")
                    SecureField("Password", text: $viewModel.password)
                        .focused($focus, equals: .password)
                        .textContentType(.password)
                        .submitLabel(.next)
                        .disabled(newUsername.isEmpty)
                        .opacity(newUsername.isEmpty ? 0.5 : 1.0)
                        .onSubmit {
                            self.focus = .confirmPassword
                        }
                }
                .padding(.vertical, 6)
                .background(Divider(), alignment: .bottom)
                .padding(.bottom, 8)
                
                HStack {
                    Image(systemName: "lock")
                    SecureField("Confirm password", text: $viewModel.confirmPassword)
                        .focused($focus, equals: .confirmPassword)
                        .disabled(newUsername.isEmpty)
                        .opacity(newUsername.isEmpty ? 0.5 : 1.0)
                        .submitLabel(.go)
                        .onSubmit {
                            signUpWithEmailPassword()
                        }
                }
                .padding(.vertical, 6)
                .background(Divider(), alignment: .bottom)
                .padding(.bottom, 8)
                
                
                if !viewModel.errorMessage.isEmpty {
                    VStack {
                        Text(viewModel.errorMessage)
                            .foregroundColor(Color(UIColor.systemRed))
                    }
                }
                
                Button(action: signUpWithEmailPassword) {
                    if viewModel.authenticationState != .authenticating {
                        Text("Sign up")
                            .minimumScaleFactor(0.5)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                    else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.isValid)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                
                VStack {
                    Text("Already have an account?")
                    Button(action: { viewModel.switchFlow() }) {
                        Text("Log in")
                            .minimumScaleFactor(0.5)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .padding([.top, .bottom], 50)
                
            }
            .padding(.horizontal, 10)
            .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
        }
        .listStyle(.plain)
        .padding()
    }
}

