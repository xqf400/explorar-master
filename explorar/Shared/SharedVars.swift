//
//  SharedVars.swift
//  explorar
//
//  Created by Fabian Kuschke on 06.08.25.
//

import SwiftUI
import Translation

var isInTestMode = false

// MARK: Gradients
var backgroundGradient: LinearGradient {
    var color1 = Color(red: 80 / 255, green: 191 / 255, blue: 219 / 255)
    var color2 = Color(red: 73 / 255, green: 73 / 255, blue: 175 / 255)
    if UserDefaults.standard.string(forKey: "appcolor") == "green" {
        color1 = Color(red: 62 / 255, green: 201 / 255, blue: 108 / 255)
        color2 = Color(red: 0 / 255, green: 135 / 255, blue: 38 / 255)
    }
    return LinearGradient(gradient: Gradient(colors: [color1, color2]),
                          startPoint: .topLeading, endPoint: .bottomTrailing)
}

var foregroundGradient: LinearGradient {
    let color1 = Color(red: 80 / 255, green: 201 / 255, blue: 222 / 255)
    return LinearGradient(gradient: Gradient(colors: [color1, .green]),
                          startPoint: .topLeading, endPoint: .bottomTrailing)
}
var foregroundGradient2: LinearGradient {
    let color1 = Color(red: 80 / 255, green: 201 / 255, blue: 222 / 255)
    return LinearGradient(gradient: Gradient(colors: [.green, color1]),
                          startPoint: .topLeading, endPoint: .bottomTrailing)
}

var allRadientGreenBlue: LinearGradient {
    return LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                          startPoint: .topLeading, endPoint: .bottomTrailing)
}

var allRadientBlueGreen: LinearGradient {
    return LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]),
                          startPoint: .topLeading, endPoint: .bottomTrailing)
}

func getDeviceLanguage() -> String {
    if let languageCode = Locale.current.language.languageCode?.identifier {
        return languageCode
    } else {
        return "en"
    }
}
/*
//MARK: Translation old
@available(iOS 18.0, *)
struct TranslatePOIModifier: ViewModifier {
    let poi: PointOfInterest
    let onTranslated: (Result<PointOfInterest, Error>) -> Void
    @Binding var isTranslating: Bool
    
    @State private var translationConfig: TranslationSession.Configuration?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard let sourceLang = languageFromCode(poi.poiLanguage) else {
                    onTranslated(.failure(TranslationError.unsupportedSourceLanguage(poi.poiLanguage)))
                    return
                }
                
                translationConfig = TranslationSession.Configuration(
                    source: sourceLang,
                    target: deviceLanguage()
                )
            }
            .translationTask(translationConfig) { session in
                guard translationConfig != nil else { return }
                await MainActor.run {
                    isTranslating = true
                }
                do {
                    let translatedPOI = try await translate(poi: poi, using: session)
                    onTranslated(.success(translatedPOI))
                } catch {
                    onTranslated(.failure(error))
                }
                await MainActor.run {
                    isTranslating = false
                }
            }
    }
}

enum TranslationError: LocalizedError {
    case unsupportedSourceLanguage(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedSourceLanguage(let lang):
            return "Unsupported source language code: \(lang)"
        }
    }
}

func languageFromCode(_ code: String) -> Locale.Language? {
    guard code.count == 2 else { return nil }
    return Locale.Language(identifier: code.lowercased())
}

func deviceLanguage() -> Locale.Language {
    if let code = Locale.preferredLanguages.first?.prefix(2) {
        print("deviceLanguageCode \(code)")
        return Locale.Language(identifier: String(code))
    }
    return Locale.Language(identifier: "en")
}

@available(iOS 18.0, *)
func translate(poi: PointOfInterest, using session: TranslationSession) async throws -> PointOfInterest {
    let deviceLangCode = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
    let poiLangCode = poi.poiLanguage.lowercased()
    if poiLangCode == deviceLangCode {
        return poi
    }
    
    func translateIfNeeded(_ text: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }
        return try await session.translate(text).targetText
    }
    
    var translatedShortInfos: [String] = []
    for shortinfo in poi.shortInfos {
        let translated = try await translateIfNeeded(shortinfo)
        translatedShortInfos.append(translated)
    }
    let translatedText = try await translateIfNeeded(poi.text)
    let translatedQuestion = try await translateIfNeeded(poi.question)
    let translatedChallenge = try await translateIfNeeded(poi.challenge)
    
    var translatedAnswers: [String] = []
    for answer in poi.answers {
        let translated = try await translateIfNeeded(answer)
        translatedAnswers.append(translated)
    }
    
    var translatedPOI = poi
    translatedPOI.shortInfos = translatedShortInfos
    translatedPOI.text = translatedText
    translatedPOI.question = translatedQuestion
    translatedPOI.answers = translatedAnswers
    translatedPOI.poiLanguage = String(deviceLangCode)
    translatedPOI.challenge = translatedChallenge
    
    return translatedPOI
}

extension View {
    @ViewBuilder
    func translatePOI(
        _ poi: PointOfInterest,
        isTranslating: Binding<Bool>,
        onTranslated: @escaping (Result<PointOfInterest, Error>) -> Void
    ) -> some View {
        if #available(iOS 18.0, *) {
            self.modifier(
                TranslatePOIModifier(
                    poi: poi,
                    onTranslated: onTranslated,
                    isTranslating: isTranslating
                )
            )
        } else {
            self
        }
    }
}*/

// MARK: Translation new
@inline(__always)
func deviceLang2() -> String {
    (Locale.preferredLanguages.first?
        .split(separator: "-").first.map(String.init)?.lowercased()) ?? "en"
}
@inline(__always)
func normalizeLang2(_ code: String) -> String? {
    let two = code.split(separator: "-").first.map(String.init)?.lowercased() ?? code.lowercased()
    return two.count == 2 ? two : nil
}
@inline(__always)
func previewDbg(_ s: String, limit: Int = 80) -> String {
    s.count <= limit ? s : String(s.prefix(limit)) + "…"
}
@inline(__always)
func sanitize(_ s: String, label: String) -> String {
    var t = s
    let before = t
    t = t
        .replacingOccurrences(of: "\u{2011}", with: "-")
        .replacingOccurrences(of: "\u{2013}", with: "-")
        .replacingOccurrences(of: "\u{2014}", with: "-")
        .replacingOccurrences(of: "\u{00A0}", with: " ")
        .replacingOccurrences(of: "\u{2028}", with: " ")
        .replacingOccurrences(of: "\u{2029}", with: " ")
        .replacingOccurrences(of: "\r", with: "\n")
    if t != before {
        print("Translate Sanitize[\(label)] applied")
    }
    return t
}

@available(iOS 18.0, *)
struct TranslatePOIModifierIOS18: ViewModifier {
    let poi: PointOfInterest
    let onTranslated: (Result<PointOfInterest, Error>) -> Void
    @Binding var isTranslating: Bool

    @State private var cfg: TranslationSession.Configuration?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard
                    let src2 = normalizeLang2(poi.poiLanguage),
                    let src = Locale.Language(identifier: src2) as Locale.Language?,
                    let tgt = Locale.Language(identifier: deviceLang2()) as Locale.Language?
                else {
                    onTranslated(.success(poi)) // Fallback
                    return
                }
                cfg = .init(source: src, target: tgt)
                print("Translate Config languages: source:", src.languageCode?.identifier ?? "und",
                      "target:", tgt.languageCode?.identifier ?? "und")
                print("Translate device Lang", deviceLang2(), "poi Lang", src2)
            }
            .translationTask(cfg) { session in
                guard cfg != nil else { return }
                await MainActor.run { isTranslating = true }
                defer { Task { @MainActor in isTranslating = false } }

                // Gleichsprachig return
                let dev = deviceLang2()
                let src2 = normalizeLang2(poi.poiLanguage) ?? "und"
                if src2 == dev {
                    print("Translate Same language – skip translation")
                    onTranslated(.success(poi))
                    return
                }

                // 1) Prepare
                do {
                    print("Translate prepareTranslation()…")
                    try await session.prepareTranslation()
                    print("Translate prepareTranslation() done")
                } catch {
                    let ns = error as NSError
                    print("Translate ERROR[prepare]:", ns.domain, ns.code, ns.localizedDescription)
                    onTranslated(.success(poi))
                    return
                }

                // 2) Übersetzen Feld für Feld
                func translateIfNeeded(_ text: String, label: String) async throws -> String {
                    let cleaned = sanitize(text, label: label).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty else {
                        print("Translate SKIP \(label): empty")
                        return text
                    }
                    print("Translate → \(label) len:", cleaned.count, "preview:", previewDbg(cleaned))
                    do {
                        let out = try await session.translate(cleaned).targetText
                        print("Translate ← \(label) len:", out.count, "preview:", previewDbg(out))
                        return out
                    } catch {
                        let ns = error as NSError
                        print("Translate ERROR[\(label)] first:", ns.domain, ns.code, ns.localizedDescription)
                        try await Task.sleep(nanoseconds: 150_000_000)
                        let out = try await session.translate(cleaned).targetText
                        print("Translate ← \(label) after retry len:", out.count, "preview:", previewDbg(out))
                        return out
                    }
                }

                do {
                    var out = poi

                    // shortInfos
                    var infos: [String] = []
                    for (i, s) in poi.shortInfos.enumerated() {
                        do { infos.append(try await translateIfNeeded(s, label: "shortInfos[\(i)]")) }
                        catch {
                            let ns = error as NSError
                            print("Translate ERROR[shortInfos[\(i)]]:", ns.domain, ns.code, ns.localizedDescription)
                            infos.append(s)
                        }
                    }
                    out.shortInfos = infos

                    // text
                    do { out.text = try await translateIfNeeded(poi.text, label: "text") }
                    catch {
                        let ns = error as NSError
                        print("Translate ERROR[text]:", ns.domain, ns.code, ns.localizedDescription)
                    }

                    // question
                    do { out.question = try await translateIfNeeded(poi.question, label: "question") }
                    catch {
                        let ns = error as NSError
                        print("Translate ERROR[question]:", ns.domain, ns.code, ns.localizedDescription)
                    }

                    // challenge
                    do { out.challenge = try await translateIfNeeded(poi.challenge, label: "challenge") }
                    catch {
                        let ns = error as NSError
                        print("Translate ERROR[challenge]:", ns.domain, ns.code, ns.localizedDescription)
                    }

                    // answers
                    var ans: [String] = []
                    for (i, a) in poi.answers.enumerated() {
                        do { ans.append(try await translateIfNeeded(a, label: "answers[\(i)]")) }
                        catch {
                            let ns = error as NSError
                            print("Translate ERROR[answers[\(i)]]:", ns.domain, ns.code, ns.localizedDescription)
                            ans.append(a)
                        }
                    }
                    out.answers = ans

                    out.poiLanguage = dev
                    onTranslated(.success(out))
                } catch {
                    let ns = error as NSError
                    print("Translate ERROR[translate pipeline]:", ns.domain, ns.code, ns.localizedDescription)
                    onTranslated(.success(poi))
                }
            }
    }
}

struct TranslatePOIModifierFallback: ViewModifier {
    let poi: PointOfInterest
    let onTranslated: (Result<PointOfInterest, Error>) -> Void
    @Binding var isTranslating: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                print("Translate iOS 17 fallback – no on-device translation")
                onTranslated(.success(poi))
            }
    }
}

extension View {
    @ViewBuilder
    func translatePOI1(
        _ poi: PointOfInterest,
        isTranslating: Binding<Bool>,
        onTranslated: @escaping (Result<PointOfInterest, Error>) -> Void
    ) -> some View {
        if #available(iOS 18.0, *), _isDebugAssertConfiguration() == false || true {
            // iOS 18 Pfad
            self.modifier(TranslatePOIModifierIOS18(poi: poi, onTranslated: onTranslated, isTranslating: isTranslating))
        } else {
            // iOS 17 Pfad
            self.modifier(TranslatePOIModifierFallback(poi: poi, onTranslated: onTranslated, isTranslating: isTranslating))
        }
    }
}
