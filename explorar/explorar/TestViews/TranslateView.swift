//
//  TranslateView.swift
//  explorar
//
//  Created by Fabian Kuschke on 07.08.25.
//

import SwiftUI
import Translation

struct POITranslationView: View {
    let pointOfInterest: PointOfInterest
    @State private var translatedPOI: PointOfInterest?
    @State private var errorMessage: String?
    @State private var isTranslating = false
    
    var body: some View {
        VStack {
            if isTranslating {
                ProgressView("Translating...")
            }
            if let translated = translatedPOI {
                Divider()
                Text("Translated shortInfo:")
                    .font(.headline)
                
                Text("Translated text:")
                    .font(.headline)
                Text(translated.text)
                
                Text("Translated question:")
                    .font(.headline)
                Text(translated.question)
                
                Text("Translated answers:")
                    .font(.headline)
                VStack(alignment: .leading) {
                    ForEach(translated.answers, id: \.self) { answer in
                        Text("- \(answer)")
                    }
                }
                VStack(alignment: .leading) {
                    ForEach(translated.shortInfos, id: \.self) { info in
                        Text("- \(info)")
                    }
                }
            }
            if let error = errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .translatePOI1(pointOfInterest, isTranslating: $isTranslating) { result in
            switch result {
            case .success(let poi):
                translatedPOI = poi
                errorMessage = nil
            case .failure(let error):
                translatedPOI = nil
                errorMessage = error.localizedDescription
            }
        }
    }
    
}



