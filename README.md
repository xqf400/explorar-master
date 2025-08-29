# ExplorAR

[![iOS](https://img.shields.io/badge/iOS-17+-blue?logo=apple)](https://developer.apple.com/ios/)  [![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)](https://swift.org)  [![Xcode](https://img.shields.io/badge/Xcode-16.4-blue?logo=xcode)](https://developer.apple.com/xcode/)  [![Platform](https://img.shields.io/badge/Platform-iPhone%20%7C%20iPad-lightgrey?logo=apple)](https://developer.apple.com/)  


**Gamifizierte Stadterkundung mit Augmented Reality:**
Eine KI-gestützte App zur Vermittlung von Kultur
und Geschichte

## 🚀 Features
- **Augmented Reality:** Entdecken von Sehenswürdigkeiten in der Umgebung, Bearbeiten von Aufgaben und Anzeigen von Bildern  
- **Gamification:** Punktesystem, Rätsel, Quizze, Fortschrittsanzeige, Rangliste und Level-System  
- **KI-Integration:** Automatisch generierte Inhalte wie Kontextinformationen, Quizfragen, Audio und Bilder  
- **App Clip:** Schnellzugriff über QR-Codes ohne vollständige App-Installation  




## 🌟 Voraussetzungen für das erfolgreiche Kompilieren
Zum Erstellen der App werden folgende Dateien benötigt, die nicht im Repository enthalten sind:
- `GoogleService-Info.plist`

`Key.swift` mit folgenden Konstanten:
- let oneSignalID = "" // OneSignal App ID
- let oneSignalKey = "" // OneSignal API Key
- let telemetryKey = "" // TelemetryDeck App Key

## 📲 TestFlight Beta

Die aktuelle Beta-Version der App kann hier getestet werden:

[![TestFlight](https://img.shields.io/badge/TestFlight-Join%20Beta-blue?logo=apple)](https://testflight.apple.com/join/jRX7TmKm)


## 💻 Testmodus (Fragezeichen-Button)
In der App ist ein Testmodus integriert, mit dem sich jede Aufgabe (bis auf die AR-Suche) gezielt prüfen lässt.
Nach dem Aktivieren bzw. Deaktivieren sollte die App neu gestartet werden.

## 📌 Beispiel App Clips
Vorab muss der App Clip über TestFlight installiert werden.
Anschließend in den Entwicklereinstellungen ein lokales Erlebnis hinzufügen mit folgenden Angaben:
- **URL Prefix:** `https://explor-ar.fun/?id=stuttgartp1` (oder `p2`, `p3` …)  
- **Bundle ID:** `com.fku.explorar.Clip`  
- **App Clip Card:** Inhalte entsprechend ausfüllen  

Anschließend mit der Kamera einen der folgenden QR-Codes scannen:

<table>
  <tr>
    <td align="center">
      <img src="Files/stuttgartp1.png" alt="Stuttgart 1" width="250"/><br/>
      <sub>Fernsehturm - Lächelnder Selfie</sub>
    </td>
    <td align="center">
      <img src="Files/stuttgartp2.png" alt="Stuttgart 2" width="250"/><br/>
      <sub>Schlossplatz - Worträtsel</sub>
    </td>
    <td align="center">
      <img src="Files/stuttgartp3.png" alt="Stuttgart 3" width="250"/><br/>
      <sub>Mercedes-Benz Museum - Quiz</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="Files/stuttgartp4.png" alt="Stuttgart 4" width="250"/><br/>
      <sub>Wilhelma - Objekterkennung</sub>
    </td>
    <td align="center">
      <img src="Files/stuttgartp5.png" alt="Stuttgart 5" width="250"/><br/>
      <sub>Stuttgarter Frühlingsfest Zeichnen</sub>
        <td align="center">
      <img src="Files/stuttgartp7.png" alt="Stuttgart 6" width="250"/><br/>
      <sub>Staatsgalerie - AR-Suche</sub>
    </td>
  </tr>
</table>


## AR-Suche Datei
Dies kann möglicherweise nicht funktionieren, da die AR-Szene grundsätzlich an die jeweilige Szene vor Ort gebunden ist.

⬇️ [ AR-Suche Datei herunterladen](./Files/QR-Code-AR-Suche.pdf?raw=true)


## 📄 Klickdummy
⬇️ [ Klickdummy herunterladen](./Files/Klickdummy.pdf?raw=true)


## 📄 Nutzerevaluation Fragebogen
⬇️ [ Fragebogen herunterladen](./Files/Nutzerevaluation.pdf?raw=true)

## 🔧 Installation & Setup
1. Repository klonen.
2. Projekt in **Xcode 16.4+** öffnen.
3. **Signing** einrichten: In `Targets > ExplorAR` und `ExplorAR Clip`
   unter *Signing & Capabilities* ein Developer-Team wählen und Bundle Identifier in eigene ändern.
4. **Konfigurationsdateien hinzufügen**:
   - `GoogleService-Info.plist` zum **App-Target** hinzufügen
   - `Key.swift` anlegen mit:
     ```swift
     let oneSignalID = "Key"
     let oneSignalKey = "Key"
     let telemetryKey = "Key"
     ```
5. **Swift Packages auflösen**: *File → Packages → Resolve Package Versions*
6. **Build & Run**: `⌘R`.


## 📓 Externe Bibliotheken
Die App verwendet folgende externe Bibliothek:
- [ARKit-CoreLocation](https://github.com/AndrewHartAR/ARKit-CoreLocation)

Alle weiteren Abhängigkeiten sind im Swift Package Manager in Xcode einsehbar.

## 📝 Lizenz  
Dieses Projekt steht unter der [MIT-Lizenz](./LICENSE).  
