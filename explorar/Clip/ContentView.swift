//
//  ContentView.swift
//  Clip
//
//  Created by Fabian Kuschke on 30.07.25.
//

import SwiftUI
import Drops

struct ContentView: View {
    @Binding var contentID: String?
    @State var point: PointOfInterest?
    // @State var contentID2: String?
    // @State private var inputText: String = "plochingenp2"
    @State var loading = false
    @State var showQRcodeView: Bool = false
    @State private var locations: [String] = []
    @State private var downloadedImage: UIImage? = nil
    @State var showNextScreen = false
    
    var customTransition: AnyTransition {
        AnyTransition.asymmetric(insertion: .offset(y:50).combined(with: .opacity), removal: .offset(y: -50).combined(with: .opacity))
    }
    
    private func loadPlist (id: String) {
        loading = true
        downloadFileFromFireBase(name: "\(id).plist", folder: "Locations", safeFile: false) { data in
            if let pointOfInterest = decodePointOfInterest(from: data) {
                print("PointOfInterest: \(pointOfInterest.id)")
                self.point = pointOfInterest
                loading = false
            } else {
                contentID = nil
                print("Failed to decode PointOfInterest")
                loading = false
                Drops.show(Drop(title: "Failed to decode PointOfInterest"))
            }
        } failure: { error in
            contentID = nil
            print("error Download Firebase \(error)")
            loading = false
            if error.contains("404") {
                Drops.show(Drop(title: "Sehenswürdigkeit konnte nicht gefunden werden."))
            } else {
                Drops.show(Drop(title: "error \(error)"))
            }
        }
    }
    func downloadRecognizeImage(point: PointOfInterest) {
        guard let imageName = point.images.first else { return }
        loading = true
        downloadFirebaseImage(name: imageName, folder: "images/\(point.id)") { image in
            DispatchQueue.main.async {
                self.downloadedImage = image
                loading = false
            }
        } failure: { errorString in
            print("Download failed: \(errorString)")
            loading = false
            Drops.show(Drop(title: "Download failed: \(errorString)"))
        }
    }
    
//    private func loadLocations() {
//        loading = true
//        downloadFileListJSON(success: { list in
//            self.locations = list
//            loading = false
//            message = "Select a location from the list."
//        }, failure: { error in
//            message = error
//            loading = false
//        })
//    }
    var body: some View {
            ZStack {
                VStack {
                    if let point {
                        NavigationStack {
                            PointOfInterestView(pointOfInterest: point) {value in
                                print("No dismiss action")
                            }
                        }
                    }
                }

                    if contentID == nil {
                        VStack {
                            Spacer()
                            Text("Please scan a QR Code!")
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(.black)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .background {
                                    Rectangle()
                                        .fill(.white)
                                        .frame(width: 260, height: 60)
                                        .cornerRadius(30)
                                }
                            Spacer()
                        }
                        VStack {
                            Spacer()
                            Button {
                                showQRcodeView = true
                            } label: {
                                Text("Scan QR-Code")
                                    .minimumScaleFactor(0.5)
                                    .foregroundStyle(.black)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                
                            }
                            .background {
                                Rectangle()
                                    .fill(foregroundGradient)
                                    .frame(width: 220, height: 60)
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                    .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                            }
                            Spacer().frame(height: 30)
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                backgroundGradient
                    .ignoresSafeArea(.all)
            )
            .sheet(isPresented: $showQRcodeView, content: {
                QRcodeScannerView(contentID: $contentID, isShowing: $showQRcodeView)
                    .presentationDetentsSheet(height: 500)
            })
            .loadingOverlay(isPresented: $loading)
            .onChange(of: contentID) { oldValue, newValue in
                guard let id = newValue else { return }
                loadPlist(id: id)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let contentID = contentID {
                        // Perform actions based on the contentID
                        print("Content ID: \(contentID)")
                        loadPlist(id: contentID)
                    }
                }
                // loadLocations()
            }
            .onChange(of: point) { oldValue, newValue in
                if point != nil {
                    if point!.challengeId == 5 && downloadedImage == nil && !loading {
                        downloadRecognizeImage(point: point!)
                    }
                }
            }
        }
        //        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
        //            // print("test")
        //            guard let incomingUrl = activity.webpageURL, let urlComponents = URLComponents(url: incomingUrl, resolvingAgainstBaseURL: true), let queryItems = urlComponents.queryItems, let id = queryItems.first(where: {$0.name == "id"})?.value else {
        //                return
        //            }
        //            contentID2 = id
        //        }
}

//extension String: Identifiable {
//    public var id: String { self }
//}
