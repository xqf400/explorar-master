//
//  LoginView.swift
//  explorar
//
//  Created by Fabian Kuschke on 18.07.25.
//

import SwiftUI
import Combine
import AuthenticationServices
import Drops

private enum FocusableField: Hashable {
    case email
    case password
}

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    // @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var showUsernameAlert = false
    
    @FocusState private var focus: FocusableField?
    
    private func signInWithEmailPassword() {
        Task {
            if await viewModel.signInWithEmailPassword() == true {
                // dismiss()
                print("logged in")
            }
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
            Spacer()
            VStack {
                Text("Login")
                    .minimumScaleFactor(0.5)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Image(systemName: "at")
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($focus, equals: .email)
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
                        .submitLabel(.go)
                        .onSubmit {
                            signInWithEmailPassword()
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
                
                Button(action: signInWithEmailPassword) {
                    if viewModel.authenticationState != .authenticating {
                        Text("Login")
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
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                
                HStack {
                    VStack { Divider() }
                    Text("or")
                        .minimumScaleFactor(0.5)
                    VStack { Divider() }
                }
                
                SignInWithAppleButton(.signIn) { request in
                    viewModel.handleSignInWithAppleRequest(request)
                } onCompletion: { result in
                    viewModel.handleSignInWithAppleCompletion(result) { loggedIn in
                        FirestoreService.shared.checkIfUserExists { result in
                            switch result {
                            case .success(let exists):
                                if !exists {
                                    print("User does NOT exist-> username alert")
                                    viewModel.shouldShowMissingUsernameAlert = true
                                } else {
                                    FirestoreService.shared.getUser { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success(_): break
                                            case .failure(let error):
                                                print("Error get User: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                    
                                }
                            case .failure(let error):
                                print("Error checking user: \(error.localizedDescription)")
                                Drops.show(Drop(title: "Error checking user: \(error.localizedDescription)"))
                            }
                        }
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
                
                Spacer().frame(height: 16)
                VStack {
                    Text("Don't have an account yet?")
                    Button(action: { viewModel.switchFlow() }) {
                        Text("Sign up")
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

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            LoginView()
//        }
//        .environmentObject(AuthenticationViewModel())
//    }
//}
