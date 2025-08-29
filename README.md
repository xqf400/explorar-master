# ExplorAR

iOS App

Gamifizierte Stadterkundung mit Augmented Reality:
Eine KI-gestützte App zur Vermittlung von Kultur
und Geschichte

## 🌟 Vorraussetzungen zum erfolgreichen Kompilieren
Zum Erstellen wird folgendes benötigt und ist nicht enthalten:
- GoogleService-Info.plist

Key.swift Datei mit folgenden Konstanten:
- let oneSignalID = "" // TODO: Id von OneSignal
- let oneSignalKey = "" // TODO: API Key von OneSignal
- let telemetryKey = "" // TODO: Telemetrydeck App Key

## 📲 TestFlight Beta

Die Beta-Version der App kann hier getestet werden:

[![TestFlight](https://img.shields.io/badge/TestFlight-Join%20Beta-blue?logo=apple)](https://testflight.apple.com/join/jRX7TmKm)


## 💻 Testmodus (Fragezeichen-Button)
Es gibt einen Testmodus in der App um jede Aufgabe testen zu können. Beim aktivieren, bzw. deaktivieren muss circa 20 Skeunden gewartet werden, damit die Daten geladen werden.

## 📌 Beispiel App Clips
Davor App Clip via TestFlight installieren. 
Ein lokales Erlebnis in den Entwicklereinstellungen hinzufügen mit folgenden Daten:
- URl Prefix https://explor-ar.fun/?id=stuttgartp1 oder p2
- Bundle ID: com.fku.explorar.Clip
- App Clip Card Daten mit Inhalt füllen.

Anschließend mit der Kamera einen  der folgenden QR-Codes scannen:

<table>
  <tr>
    <td align="center">
      <img src="Files/stuttgartp1.png" alt="Stuttgart 1" width="250"/><br/>
      <sub>Fernseherturm Lächelnder Selfie</sub>
    </td>
    <td align="center">
      <img src="Files/stuttgartp2.png" alt="Stuttgart 2" width="250"/><br/>
      <sub>Schlossplatz Worträtsel</sub>
    </td>
    <td align="center">
      <img src="Files/stuttgartp3.png" alt="Stuttgart 3" width="250"/><br/>
      <sub>Mercedes-Benz Museum Quiz</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="Files/stuttgartp4.png" alt="Stuttgart 4" width="250"/><br/>
      <sub>Wilhelma Objekterkennung</sub>
    </td>
    <td align="center">
      <img src="Files/stuttgartp5.png" alt="Stuttgart 5" width="250"/><br/>
      <sub>Stuttgarter Frühlingsfest Zeichnen</sub>
        <td align="center">
      <img src="Files/stuttgartp7.png" alt="Stuttgart 6" width="250"/><br/>
      <sub>Staatsgalerie AR-Suche</sub>
    </td>
  </tr>
</table>



⬇️ [ AR-Suche Datei herunterladen](./Files/QR-Code-AR-Suche.pdf?raw=true)



## 📄 Klickdummy
⬇️ [ Klickdummy herunterladen](./Files/Klickdummy.pdf?raw=true)

## 📓 Externe Bibliotheken
ARKit-CoreLocation
https://github.com/AndrewHartAR/ARKit-CoreLocation
