//
//  ClipApp.swift
//  Clip
//
//  Created by Fabian Kuschke on 30.07.25.
//

import SwiftUI

@main
struct ClipApp: App {
    @State private var contentID: String? = nil
    
    var body: some Scene {
        WindowGroup {
            ContentView(contentID: $contentID)
                .onOpenURL { url in
                    print("url1 ", url)
                    parse(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        print("url2 ", url)
                        parse(url: url)
                    }
                }
        }
    }
    private func parse(url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let idParam = components.queryItems?.first(where: { $0.name == "id" })?.value {
            contentID = idParam
        }
    }
}
