# P2pChords

## Übersicht
P2pChords ist eine Flutter App zur Visualisierung und der synchronisierten Nutzung von Liedtexten und Akkorden in Echtzeit. Die App ermöglicht eine Synchronisation via Peer-to-Peer und einer Websocket verbindung zwischen mehreren Geräten (Client und Server struktur), sodass Teams und Bands dieselben Texte und Akkorde gleichzeitig anzeigt bekommen können.

## Hauptfunktionen

### Liedverwaltung
- **Liedsammlungen**: Ermöglicht das Organisieren von Lieder in verschiedenen Gruppen
- **Schnellauswahl**: Einfache Navigation zwischen verschiedenen Songs durch eine intuitive Auswahlschnittstelle (noch nicht Implementiert)
- **Abschnittsnavigation**: Schnelles Wechseln zwischen verschiedenen Songabschnitten (Verse, Chorus, etc.)

### Akkord Visualisierung
- **Nashville-Nummern-System**: Unterstützung von Nashville-Notation mit automatischer Umwandlung zu Standardakkorden
- **Transposition**: Wechseln zwischen verschiedenen Tonarten mit sofortiger Aktualisierung der Akkorde
- **Positionierung**: Präzise Platzierung von Akkorden über dem Text

### Echtzeit-Kollaboration
- **Peer-to-Peer-Synchronisation**: Gemeinsame Nutzung von Songs und Navigation durch Songabschnitte mit mehreren Geräten
- **Server-Client-Modell**: Ein Gerät kann als Server fungieren und mehrere Clients steuern
- **Synchronisierte Änderungen**: Wechsel von Liedern und Abschnitten auf dem Server werden automatisch an alle verbundenen Clients weitergeleitet

### Bearbeitung und Anpassung
- **Integrierter Editor**: Erstellen und Bearbeiten von Songtexten und Akkorden
- **Anpassbare Darstellung**: Personalisierbare Einstellungen für Schriftgröße, Zeilenabstand und weitere anzeige Einstellungen
- **Akkordbearbeitung**: Einfaches Hinzufügen, Bearbeiten und Positionieren von Akkorden im Text

## Technische Details
- Programmiert in Flutter für plattformübergreifende Kompatibilität
- Verwendet Provider für ein effizientes State Management
- Implementiert JSON-basierte Datenstrukturen für die Speicherung von Songs und Einstellungen im Form von Class'en
- Enthält ein umfassendes Nashville-zu-Akkord mapping System für verschiedene Tonarten

## Download und Installation

### Schritt 1: NuGet herunterladen und installieren

1. **NuGet CLI herunterladen**:
   - Besuchen Sie [nuget.org/downloads](https://www.nuget.org/downloads)
   - Laden Sie die neueste Version von `nuget.exe` herunter

2. **NuGet zum PATH hinzufügen**:
   ```cmd
   # Erstellen Sie einen Ordner für nuget
      mkdir C:\tools
   
   # Kopieren Sie nuget.exe in den tools ordner Ordner
   # Dann fügen Sie den Pfad "C:\tools" zur PATH-Umgebungsvariable hinzu
   ```
   
   **Alternative über Systemeinstellungen**:
   - Öffnen Sie "Systemumgebungsvariablen bearbeiten"
   - Klicken Sie auf "Umgebungsvariablen"
   - Wählen Sie "Path" unter "Systemvariablen" und klicken Sie "Bearbeiten"
   - Klicken Sie "Neu" und fügen Sie `C:\Tools\NuGet` hinzu
   - Bestätigen Sie mit "OK"

3. **Installation überprüfen**:
   ```cmd
   nuget help
   ```

### Schritt 2: Flutter SDK installieren

   **Neueste Flutter Version herunterladen**:
   - Am besten einfach durch die VsCode Extension

### Schritt 3: Projekt herunterladen und konfigurieren

1. **Repository klonen**:
   ```cmd
   git clone [REPOSITORY_URL]
   cd P2pChords
   ```

2. **Wichtige Datei umbenennen**:
   ```cmd
   # Navigieren Sie zum Ordner lib/dataManagement/local_manager und benennen Sie die Datei config_system_stub.dart um
   zu config_system.dart
   ```

3. **Dependencies installieren**:
   ```cmd
   flutter pub get
   ```

4. **Projekt testen**:
   ```cmd
   flutter doctor -v
   flutter run -d windows
   ```

### Schritt 4: Erste Ausführung

```cmd
flutter run
```

## Verwendung

1. **Songs importieren oder erstellen**:
   - Verwenden Sie den Editor, um neue Songs zu erstellen
   - Importieren Sie vorhandene Songs im unterstützten Format

2. **Verbindung zwischen Geräten herstellen**:
   - Ein Gerät als Server einrichten
   - Andere Geräte als Clients verbinden

3. **Songs navigieren und anzeigen**:
   - Songs aus Gruppen auswählen
   - Zwischen Abschnitten navigieren
   - Tonart bei Bedarf transponieren

4. **Einstellungen anpassen**:
   - Schriftgröße, Zeilenabstand und weitere Anzeigeoptionen individuell einstellen
   - Visuelle Anpassungen vornehmen für optimale Lesbarkeit

## Fehlerbehebung

### Unterstützte Plattformen
- Windows (primär getestet)
- Android 
- iOS (nicht ausführlich getestet)

## Lizenz
JoE Lizenz