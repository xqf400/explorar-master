//
//  AiFunctions.swift
//  explorar
//
//  Created by Fabian Kuschke on 16.08.25.
//

import OpenAI
import Foundation
import UIKit
import Drops

enum POICoordError: Error { case notFound, network(Error), badResponse }

public struct POICoordinates {
    public let latitude: Double
    public let longitude: Double
}

class AIService {
    static let shared = AIService()
    
    private let client: OpenAI
    
    private init() {
        let config = OpenAI.Configuration(
            token: openAiKey,
            timeoutInterval: 180
        )
        client = OpenAI(configuration: config)
    }
    
    // MARK: getInterestingPlaces
    func getInterestingPlaces(in city: String, useOldPromt: Bool = false, completion: @escaping (Result<[PointOfInterest], Error>) -> Void
    ) {
        print("getInterestingPlaces from AI in \(city)...")
        SharedPlaces.shared.locationManager.stopUpdatingLocation()
        var message = ChatQuery.ChatCompletionMessageParam.user(
            .init(content: .string("""
            Give me up to 10 real sightseeing attractions in \(city). Do not invent landmarks.
            Example urls for searching images:
            - wikipedia.org or upload.wikimedia.org (Wikimedia/Wikipedia file URLs)
            - the site’s official domain (e.g., .museum, .edu, .gov, official .com)
            - googleusercontent.com (Maps/Places photo CDN)
            Example images for example “White House (AI)” that are acceptable:
            https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/White_House_north_and_south_sides.jpg/500px-White_House_north_and_south_sides.jpg or
            https://upload.wikimedia.org/wikipedia/commons/2/23/Château_de_Rastignac.JPG

            OUTPUT RULES (per PointOfInterest):
            - id: "\(city.lowercased())AI1", "\(city.lowercased())AI2", ...
            - name: "<Real POI name> (AI)"
            - city: "\(city)"
            - latitude/longitude: WGS84 decimal degrees with ≥5 fractional digits (e.g., 48.788550, 9.233760). Never output 0.0 and never guess. If you cannot verify precise coordinates from an authoritative page, SKIP this POI entirely.
            - text: 2–3 paragraphs, engaging but factual
            - shortInfos: exactly 3 short facts (max 5 words each)
            - images: 0–3 HTTPS URLs, allowed domains ONLY:
              * wikipedia.org or upload.wikimedia.org
              * the site’s official domain (.museum, .edu, .gov, official .com)
              * googleusercontent.com (Maps/Places photo CDN)
              If none found: []
            - modelName: ""
            - poiLanguage: "en"
            - creator: "AI"

            CHALLENGE LOGIC:
            - You must choose ONE challenge type per POI:
              (A) QUIZ  -> challengeId = 3, challenge = "Solve the quiz"
                  * question: a fun, factual question about this POI
                  * answers: exactly 4 short options
                  * correctIndex: integer 0–3 pointing to the right answer
              (B) HANGMAN -> challengeId = 4, challenge = "Guess the word"
                  * question: a short clue leading to the POI’s name or a key term
                  * answers: exactly 1 element [ "<secret-word>" ]
                    - secret-word: max 8 letters, single word, letters only (a–z), lowercase
                    - If the natural answer has spaces/diacritics/hyphens, normalize:
                      remove spaces/hyphens/diacritics and lowercase (e.g., "São Paulo" -> "saopaulo")
                  * correctIndex: 0  (always 0 for hangman)

            DECISION RULES (when to use hangman vs quiz):
            - Prefer HANGMAN if you can form a single-word secret ≤ 8 letters that clearly ties to the POI (e.g., the POI name or its iconic nickname).
            - Otherwise use QUIZ.
            - Across the list, vary types (don’t always pick the same).
            
            HARD COORDINATE RULES:
            - Only include POIs whose coordinates you can verify from an authoritative page (Wikipedia article/infobox, Wikidata P625, or the POI’s official site).
            - Provide coordinates in WGS84 decimal degrees with at least 5 decimals.
            - Latitude must be in [-90, 90]; longitude in [-180, 180].
            - Do NOT round to fewer than 5 decimals. Do NOT swap lat/lon. Do NOT output 0.0.
            - If a POI’s coordinates cannot be verified with high confidence, SKIP that POI (output fewer than 10 items if necessary).

            COORDINATE VALIDATION (do internally; do NOT output this reasoning):
            - Sanity-check that coordinates plausibly fall within or near \(city)’s urban area.
            - If multiple sources disagree, prefer Wikidata P625 (WGS84) or the Wikipedia infobox value with the most precise decimals.
            - If any rule fails, exclude the POI entirely (no placeholders).

            VALIDATION:
            - Never output invented POIs.
            - For HANGMAN, enforce answers.length == 1 and length(secret-word) ≤ 8.
            - For QUIZ, enforce answers.length == 4 and a valid correctIndex 0–3.

            """))
        )
        if useOldPromt {
            message = ChatQuery.ChatCompletionMessageParam.user(
                .init(content: .string("""
                Give me up to 10 real sightseeing attractions in \(city). Do not invent landmarks.

                OUTPUT RULES (per PointOfInterest):
                - id: "\(city.lowercased())AI1", "\(city.lowercased())AI2", ...
                - name: "<Real POI name> (AI)"
                - city: "\(city)"
                - latitude/longitude: real values if known, else 0.0
                - text: 2–3 paragraphs, engaging but factual
                - shortInfos: exactly 3 short facts (max 5 words each)
                - images: 0–3 HTTPS URLs
                  If none found: []
                - modelName: ""
                - poiLanguage: "en"
                - creator: "AI"

                CHALLENGE LOGIC:
                - You must choose ONE challenge type per POI:
                  (A) QUIZ  -> challengeId = 3, challenge = "Solve the quiz"
                      * question: a fun, factual question about this POI
                      * answers: exactly 4 short options
                      * correctIndex: integer 0–3 pointing to the right answer
                  (B) HANGMAN -> challengeId = 4, challenge = "Guess the word"
                      * question: a short clue leading to the POI’s name or a key term
                      * answers: exactly 1 element [ "<secret-word>" ]
                        - secret-word: max 8 letters, single word, letters only (a–z), lowercase
                        - If the natural answer has spaces/diacritics/hyphens, normalize:
                          remove spaces/hyphens/diacritics and lowercase (e.g., "São Paulo" -> "saopaulo")
                      * correctIndex: 0  (always 0 for hangman)

                DECISION RULES (when to use hangman vs quiz):
                - Prefer HANGMAN if you can form a single-word secret ≤ 8 letters that clearly ties to the POI (e.g., the POI name or its iconic nickname).
                - Otherwise use QUIZ.
                - Across the list, vary types (don’t always pick the same).

                VALIDATION:
                - Never output invented POIs.
                - For HANGMAN, enforce answers.length == 1 and length(secret-word) ≤ 8.
                - For QUIZ, enforce answers.length == 4 and a valid correctIndex 0–3.

                """))
            )
        }

        let schema: JSONSchema = .object([
            "type": AnyJSONDocument("object"),
            "properties": AnyJSONDocument([
                "points": AnyJSONDocument([
                    "type": AnyJSONDocument("array"),
                    "items": AnyJSONDocument([
                        "type": AnyJSONDocument("object"),
                        "properties": AnyJSONDocument([
                            "id": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "shortInfos": AnyJSONDocument([
                                "type": AnyJSONDocument("array"),
                                "items": AnyJSONDocument(["type": AnyJSONDocument("string")])
                            ]),
                            "text": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "images": AnyJSONDocument([
                                "type": AnyJSONDocument("array"),
                                "items": AnyJSONDocument(["type": AnyJSONDocument("string")])
                            ]),
                            "name": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "creator": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "city": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "latitude": AnyJSONDocument(["type": AnyJSONDocument("number")]),
                            "longitude": AnyJSONDocument(["type": AnyJSONDocument("number")]),
                            "modelName": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "poiLanguage": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "challenge": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "challengeId": AnyJSONDocument([
                                "type": AnyJSONDocument("integer"),
                                "enum": AnyJSONDocument([3, 4])
                            ]),
                            "question": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                            "answers": AnyJSONDocument([
                                "type": AnyJSONDocument("array"),
                                "items": AnyJSONDocument(["type": AnyJSONDocument("string")]),
                                "minItems": AnyJSONDocument(1),
                                "maxItems": AnyJSONDocument(4)
                            ]),
                            "correctIndex": AnyJSONDocument(["type": AnyJSONDocument("integer")])
                        ]),
                        "required": AnyJSONDocument([
                            "id", "shortInfos", "text", "images",
                            "name", "creator", "city", "latitude", "longitude",
                            "modelName", "poiLanguage", "challenge", "challengeId",
                            "question", "answers", "correctIndex"
                        ]),
                        "additionalProperties": AnyJSONDocument(false)
                    ])
                ])
            ]),
            "required": AnyJSONDocument(["points"]),
            "additionalProperties": AnyJSONDocument(false)
        ])

        
        let schemaDef: JSONSchemaDefinition = .jsonSchema(schema)
        
        let options = ChatQuery.StructuredOutputConfigurationOptions(
            name: "points_of_interest",
            description: "List of 10 sightseeing attractions for a city, with name, facts, description, optional images, and coordinates.",
            schema: schemaDef,
            strict: true
        )
        
        
        let query = ChatQuery(
            messages: [message],
            model: .gpt5,
            responseFormat: .jsonSchema(options)
        )
        
        Task {
            do {
                let result = try await client.chats(query: query)
                if let json = result.choices.first?.message.content {
                    let data = Data(json.utf8)
                    struct Wrapper: Codable { let points: [PointOfInterest] }
                    let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
                    SharedPlaces.shared.locationManager.startUpdatingLocation()
                    completion(.success(decoded.points))
                } else {
                    SharedPlaces.shared.locationManager.startUpdatingLocation()
                    completion(.failure(NSError(domain: "AIService", code: 0,
                                                userInfo: [NSLocalizedDescriptionKey: "No content returned"])))
                }
            } catch {
                print("Error fetching POIs: ", error)
                SharedPlaces.shared.locationManager.startUpdatingLocation()
                completion(.failure(error))
            }
        }
    }
    
    // MARK: Save Ai Pois local
    func savePOIs(_ pois: [PointOfInterest], for city: String) {
        do {
            let data = try JSONEncoder().encode(pois)
            let url = getAIPoisFileURL(for: city)
            try data.write(to: url)
            print("Saved AI POIs for \(city) to \(url.path)")
        } catch {
            print("Failed to save AI POIs:", error)
            Drops.show(Drop(title: "Failed to save AI POIs: \(error)"))
        }
    }

    private func getAIPoisFileURL(for city: String) -> URL {
        let docs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("\(city.lowercased())-pois.json")
    }
    // MARK: Local AI POIS
    func loadAIPOIs(for city: String) -> [PointOfInterest]? {
        print("Todo store last city or if unknown city-> to long waiting time")
        var pois: [PointOfInterest] = []
        if isInTestMode {
            do {
                let url = getAIPoisFileURL(for: "stuttgart")
                let data = try Data(contentsOf: url)
                let pois1 = try JSONDecoder().decode([PointOfInterest].self, from: data)
                for poi in pois1 {
                    if !pois.contains(where: {$0.id == poi.id}) {
                        pois.append(poi)
                    }
                }
                print("Loaded AI POIs for \(city)")
            } catch {
                print("Failed to load AI POIs:", error)
                return nil
            }
        }
        do {
            let url = getAIPoisFileURL(for: city)
            let data = try Data(contentsOf: url)
            let pois1 = try JSONDecoder().decode([PointOfInterest].self, from: data)
            for poi in pois1 {
                if !pois.contains(where: {$0.id == poi.id}) {
                    pois.append(poi)
                }
            }
            print("Loaded AI POIs for \(city)")
            return pois
        } catch {
            print("Failed to load AI POIs:", error)
            return nil
        }
    }

    // MARK: fetchWikipediaImages
    func fetchWikipediaImages(for title: String, completion: @escaping ([String]) -> Void) {
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=images&titles=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else {
            print("wiki no url")
            Drops.show(Drop(title: "wiki no url"))
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pages = (json["query"] as? [String: Any])?["pages"] as? [String: Any],
                  let page = pages.values.first as? [String: Any],
                  let images = page["images"] as? [[String: Any]] else {
                print("wiki no data")
                completion([])
                return
            }
            let jpgFileNames = images
                .compactMap { $0["title"] as? String }
                .filter {
                    let lower = $0.lowercased()
                    return lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg")
                }
                .prefix(5) // max 5 images

            var urls: [String] = []
            let group = DispatchGroup()
            for fileName in jpgFileNames {
                group.enter()
                let fileInfoUrl = "https://en.wikipedia.org/w/api.php?action=query&format=json&titles=\(fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&prop=imageinfo&iiprop=url"
                guard let imageURL = URL(string: fileInfoUrl) else { group.leave(); continue }
                URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                    defer { group.leave() }
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let pages = (json["query"] as? [String: Any])?["pages"] as? [String: Any],
                       let page = pages.values.first as? [String: Any],
                       let imageinfo = (page["imageinfo"] as? [[String: Any]])?.first,
                       let url = imageinfo["url"] as? String {
                        urls.append(url)
                    }
                }.resume()
            }
            group.notify(queue: .main) {
                print("wiki completed")
                completion(urls)
            }
        }.resume()
    }

    // MARK: fetchWikiCoordinates
    public func fetchWikiCoordinates(name: String, cityHint: String, debug: Bool = false, completion: @escaping (POICoordinates) -> Void
    ) {
        print("fetchWikiCoordinates")
        // MARK: - Helpers
        @inline(__always) func log(_ items: Any...) { if debug { print("[POICoord]", items.map { "\($0)" }.joined(separator: " ")) } }
        @inline(__always) func deliver(_ lat: Double, _ lon: Double) {
            DispatchQueue.main.async { completion(POICoordinates(latitude: lat, longitude: lon)) }
        }
        @inline(__always) func deliverZero() { deliver(0, 0) }

        func wikipediaTitleURL(title: String) -> URL? {
            var c = URLComponents(string: "https://en.wikipedia.org/w/api.php")
            c?.queryItems = [
                .init(name: "action", value: "query"),
                .init(name: "redirects", value: "1"),
                .init(name: "converttitles", value: "1"),
                .init(name: "prop", value: "coordinates|pageprops"),
                .init(name: "titles", value: title),
                .init(name: "format", value: "json"),
                .init(name: "formatversion", value: "2")
            ]
            return c?.url
        }
        func wikipediaSearchURL(query: String, limit: Int = 5) -> URL? {
            var c = URLComponents(string: "https://en.wikipedia.org/w/api.php")
            c?.queryItems = [
                .init(name: "action", value: "query"),
                .init(name: "generator", value: "search"),
                .init(name: "gsrsearch", value: query),
                .init(name: "gsrlimit", value: String(limit)),
                .init(name: "gsrnamespace", value: "0"),
                .init(name: "prop", value: "coordinates|pageprops"),
                .init(name: "format", value: "json"),
                .init(name: "formatversion", value: "2")
            ]
            return c?.url
        }
        func wikidataURL(qid: String) -> URL? {
            URL(string: "https://www.wikidata.org/wiki/Special:EntityData/\(qid).json")
        }

        // Networking
        func requestJSON(_ url: URL, _ cb: @escaping (Any?) -> Void) {
            var req = URLRequest(url: url)
            req.setValue("YourAppName/1.0 (iOS; contact@example.com)", forHTTPHeaderField: "User-Agent") // bitte anpassen
            log("GET", url.absoluteString)
            URLSession.shared.dataTask(with: req) { data, resp, err in
                if let e = err { log("Network:", e.localizedDescription); return cb(nil) }
                if let http = resp as? HTTPURLResponse { log("HTTP", http.statusCode) }
                guard let data = data else { log("No data"); return cb(nil) }
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if json == nil { log("JSON decode error") }
                cb(json)
            }.resume()
        }

        // JSON helpers
        func pages(from json: Any) -> [[String: Any]] {
            guard
                let root = json as? [String: Any],
                let query = root["query"] as? [String: Any],
                let pages = query["pages"] as? [[String: Any]]
            else { return [] }
            return pages
        }
        func firstCoords(in pages: [[String: Any]]) -> (Double, Double)? {
            for p in pages {
                if let coords = p["coordinates"] as? [[String: Any]],
                   let c0 = coords.first,
                   let lat = c0["lat"] as? Double,
                   let lon = c0["lon"] as? Double {
                    return (lat, lon)
                }
            }
            return nil
        }
        func firstQID(in pages: [[String: Any]], prefer match: String) -> String? {
            let needle = match.lowercased()
            var fallback: String?
            for p in pages {
                let title = (p["title"] as? String)?.lowercased() ?? ""
                let props = p["pageprops"] as? [String: Any]
                let qid = props?["wikibase_item"] as? String
                if let qid = qid {
                    if title.contains(needle) { return qid }
                    if fallback == nil { fallback = qid }
                }
            }
            return fallback
        }
        func extractWikidataCoords(_ json: Any, qid: String) -> (Double, Double)? {
            guard
                let root = json as? [String: Any],
                let entities = root["entities"] as? [String: Any],
                let ent = entities[qid] as? [String: Any],
                let claims = ent["claims"] as? [String: Any],
                let p625 = claims["P625"] as? [[String: Any]],
                let first = p625.first,
                let mainsnak = first["mainsnak"] as? [String: Any],
                let datavalue = mainsnak["datavalue"] as? [String: Any],
                let value = datavalue["value"] as? [String: Any],
                let lat = value["latitude"] as? Double,
                let lon = value["longitude"] as? Double
            else { return nil }
            return (lat, lon)
        }

        // Suche mit Varianten
        func searchFlowEN(_ finalIfFail: @escaping () -> Void) {
            let variants: [String] = [
                "\(name) \(cityHint)",
                name,
                "\(name.replacingOccurrences(of: "-", with: " ")) \(cityHint)"
            ]
            func tryAt(_ i: Int) {
                if i >= variants.count { return finalIfFail() }
                guard let url = wikipediaSearchURL(query: variants[i]) else { log("Bad search URL"); return tryAt(i+1) }
                requestJSON(url) { json in
                    guard let json = json else { log("Search failed"); return tryAt(i+1) }
                    let ps = pages(from: json)
                    log("Search pages(\(i)):", ps.count, "query:", variants[i])

                    if let (lat, lon) = firstCoords(in: ps) {
                        log("From search/Wikipedia:", lat, lon)
                        return deliver(lat, lon)
                    }
                    if let qid = firstQID(in: ps, prefer: name), let wd = wikidataURL(qid: qid) {
                        log("QID from search:", qid)
                        requestJSON(wd) { wdJson in
                            if let wdJson = wdJson, let (lat, lon) = extractWikidataCoords(wdJson, qid: qid) {
                                log("From Wikidata:", lat, lon)
                                deliver(lat, lon)
                            } else {
                                log("ℹ️ No P625 for", qid, "→ next variant")
                                tryAt(i+1)
                            }
                        }
                    } else {
                        log("ℹ️ No QID in search pages → next variant")
                        tryAt(i+1)
                    }
                }
            }
            tryAt(0)
        }

        // 1) Exakter Titel
        guard let titleURL = wikipediaTitleURL(title: name) else {
            log("Bad title URL")
            return searchFlowEN { deliverZero() }
        }
        requestJSON(titleURL) { titleJson in
            guard let titleJson = titleJson else {
                log("ℹ️ Title request failed → search")
                return searchFlowEN { deliverZero() }
            }
            let ps = pages(from: titleJson)
            log("Title pages:", ps.count)

            if let (lat, lon) = firstCoords(in: ps) {
                log("From Wikipedia title:", lat, lon)
                return deliver(lat, lon)
            }

            if let qid = firstQID(in: ps, prefer: name), let wdURL = wikidataURL(qid: qid) {
                log("QID from title:", qid)
                requestJSON(wdURL) { wdJson in
                    if let wdJson = wdJson, let (lat, lon) = extractWikidataCoords(wdJson, qid: qid) {
                        log("From Wikidata:", lat, lon)
                        return deliver(lat, lon)
                    }
                    log("Wikidata failed → search")
                    searchFlowEN { deliverZero() }
                }
            } else {
                log("No QID from title → search")
                searchFlowEN { deliverZero() }
            }
        }
    }


    // MARK: summarizeText
    func summarizeText(text: String, completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("summarizeText AI")
        Task {
            do {
                let query = ChatQuery(
                    messages: [
                        .user(.init(content: .string("Please summarize this text in a way that's clear and suitable to be read aloud in the language it is written in in 2 sentences:\n\n\(text)")))
                    ],
                    model: .gpt4_o
                )
                let result = try await client.chats(query: query)
                let summary = result.choices.first?.message.content ?? ""
                // print(result.choices.first?.message.content ?? "")
                print("summary successfully")
                completion(.success(summary))
            } catch {
                print("Error ai \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: downloadVoiceMp3
    func downloadVoiceMp3(_ text: String, to fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void
    ) {
        print("downloadVoiceMp3 AI")

        let query = AudioSpeechQuery(
            model: .tts_1,
            input: text,
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.0
        )
        
        _ = client.audioCreateSpeech(query: query) { res in
            switch res {
            case .failure(let err):
                DispatchQueue.main.async {
                    print("audioCreateSpeech error:", err.localizedDescription)
                    completion(.failure(err))
                }
                
            case .success(let result):
                DispatchQueue.main.async {
                    do {
                        try result.audio.write(to: fileURL, options: .atomic)
                        print("got audio and saved:", fileURL.path)
                        completion(.success(fileURL))
                    } catch {
                        print("Playback error:", error.localizedDescription)
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: identifyAnimal
    func identifyAnimal(selectedImage: UIImage, challenge: String, animalName: String, completion: @escaping (Result<AnimalRating, Error>) -> Void) {
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let otherPrompt = """
                    You are an art teacher evaluating a child's simple line drawing of an animal.
                    1) Identify the intended animal. It should be: {animalName}
                    2) Consider the challenge/context: {challenge}

                    Scoring (1–10), motivation-aware:
                    - Clearly recognizable as the intended animal → 9–10
                    - Mostly recognizable with minor ambiguity → 7–8
                    - Partly recognizable (key features present but unclear) → 5–6
                    - Not recognizable / wrong animal → 2–4
                    - No relevant drawing → 1

                    Motivation safeguard:
                    - If the intended animal is reasonably recognizable, avoid very low scores (≤4).
                    - Always provide encouraging, constructive feedback (1 positive observation + 1 concrete suggestion).
                """

        
        let message = ChatQuery.ChatCompletionMessageParam.user(
            .init(content: .contentParts([
                .image(
                    .init(
                        imageUrl: .init(
                            imageData: imageData,
                            detail: ChatQuery.ChatCompletionMessageParam.ContentPartImageParam.ImageURL.Detail.high
                        )
                    )
                ),
                .text(.init(text: """
                    You are an art teacher evaluating a child's sketch. 
                    Identify the intended animal in the image. It should be a \(animalName)
                    The challenge was: \(challenge)
                    
                    Scoring rules (strict):
                    - If the animal is clearly identifiable without doubt → rating = 10
                    - If mostly identifiable with minor uncertainty → rating = 9
                    - Anything else → 8 or below
                    
                    Be generous: internet-quality, realistic, or professional-looking images that match the animal perfectly should always get 10.
                    
                    if you think it looks like an other animal please tell me in the JSON the animal you think it looks like.
                    
                    Return ONLY valid JSON with:
                    {
                      "name": "<animal in lowercase>",
                      "rating": <integer from 1 to 10>
                    }
                    """))
            ]))
        )
        
        let schema: JSONSchema = .object([
            "type": AnyJSONDocument("object"),
            "properties": AnyJSONDocument([
                "name": AnyJSONDocument([
                    "type": AnyJSONDocument("string")
                ]),
                "rating": AnyJSONDocument([
                    "type": AnyJSONDocument("integer")
                ])
            ]),
            "required": AnyJSONDocument(["name", "rating"]),
            "additionalProperties": AnyJSONDocument(false)
        ])
        
        let schemaDef: JSONSchemaDefinition = .jsonSchema(schema)
        
        // desc for context
        let options = ChatQuery.StructuredOutputConfigurationOptions(
            name: "animal_rating",
            description: "For a child's drawing, identify the intended animal and give a generous, encouraging rating from 1–10 based on recognizability. Ignore colors.",
            schema: schemaDef,
            strict: true
        )
        let query = ChatQuery(
            messages: [message],
            model: .gpt4_o_mini,
            responseFormat: .jsonSchema(options)
        )
        
        _ = client.chats(query: query) { result in
            switch result {
            case .success(let response):
                if let text = response.choices.first?.message.content {
                    print("AI says:", text)
                    // loading = false
                    if let jsonData = text.data(using: .utf8) {
                        do {
                            let decoded = try JSONDecoder().decode(AnimalRating.self, from: jsonData)
                            completion(.success(decoded))
                        } catch {
                            completion(.failure(error))
                        }
                    } else {
                        completion(.failure(NSError(domain: "AIService", code: 0,
                                                    userInfo: [NSLocalizedDescriptionKey: "No structured result found."])))
                    }
                } else {
                    print("No text output.")
                    completion(.failure(NSError(domain: "AIService", code: 0,
                                                userInfo: [NSLocalizedDescriptionKey: "No text output."])))
                }
            case .failure(let error):
                print("Error:", error)
                completion(.failure(error))
            }
        }
    }
    
}
