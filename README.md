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

## Installation

```
flutter pub get
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

## Voraussetzungen
- Flutter SDK
- Unterstützte Plattformen: Android, iOS (nicht ausführlich getested), Windows

## Lizenz
JoE Lizenz