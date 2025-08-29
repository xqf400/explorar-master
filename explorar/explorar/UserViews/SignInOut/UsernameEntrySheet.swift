//
//  UsernameEntrySheet.swift
//  explorar
//
//  Created by Fabian Kuschke on 28.07.25.
//

import SwiftUI
import Drops

struct UsernameEntrySheet: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @State var tempUsername: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Enter username")
                .minimumScaleFactor(0.5)
                .font(.headline)
            TextField("Username", text: $tempUsername)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .submitLabel(.go)
                .onSubmit {
                    if !tempUsername.isEmpty {
                        Task {
                            let success = await viewModel.setUsername(tempUsername)
                            if success {
                                print("Username updated successfully!")
                                FirestoreService.shared.createDatabaseUser { result in
                                    switch result {
                                    case .success():
                                        print("User created in Firestore")
                                        dismiss()
                                    case .failure(let error):
                                        print("Firestore error: \(error)")
                                        Drops.show(Drop(title: "Firestore error: \(error)"))
                                    }
                                }
                            } else {
                                print("Error: \(viewModel.errorMessage)")
                                Drops.show(Drop(title: "Error: \(viewModel.errorMessage)"))
                            }
                        }
                    }
                }
            Button("Set username") {
                Task {
                    let success = await viewModel.setUsername(tempUsername)
                    if success {
                        print("Username updated successfully!")
                        FirestoreService.shared.createDatabaseUser { result in
                            switch result {
                            case .success():
                                print("User created in Firestore")
                                dismiss()
                            case .failure(let error):
                                print("Firestore error: \(error)")
                                Drops.show(Drop(title: "Firestore error: \(error)"))

                            }
                        }
                    } else {
                        print("Error: \(viewModel.errorMessage)")
                        Drops.show(Drop(title: "Error: \(viewModel.errorMessage)"))
                    }
                }
            }
            .disabled(tempUsername.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .interactiveDismissDisabled(true)
    }
}
