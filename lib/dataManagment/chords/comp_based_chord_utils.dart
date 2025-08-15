class ChordUtils {

  static const List<String> _sharpKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#', 'G#', 'D#', 'A#'];
  static const List<String> _notesSharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const List<String> _notesFlat = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  static const Map<String, List<int>> _scaleIntervals = {
    'major': [0, 2, 4, 5, 7, 9, 11],
    'minor': [0, 2, 3, 5, 7, 8, 10],
  };

  static const List<String> _majorScaleQualities = ['', 'm', 'm', '', '', 'm', 'dim'];
  static const List<String> _minorScaleQualities = ['m', 'dim', '', 'm', 'm', '', ''];



  static final RegExp _bassNotePattern = RegExp(r'^[A-Ga-g][#b]?$');

  static final RegExp _chordPattern = RegExp(r'^([A-Ga-g][#b]?)' // Root note
      r'(m|maj|min|aug|dim|sus|add|\+|°|ø|-)?' // Quality/type
      r'(\d+)?' // Number/extension (7, 9, etc.)
      r'(sus\d+|add\d+|aug|dim|\+|\(.*?\))*' // Additional modifiers (allow multiple)
      r'(\*)?$' // Optional trailing asterisk
      );

  /// Parses a key string (e.g., "C#m") into its root note and scale type.
  static Map<String, String> parseKey(String key) {
    if (key.endsWith('m') && !key.endsWith('dim') && key.length > 1) {
      // It's a minor key, e.g., "Am" or "C#m"
      return {'root': key.substring(0, key.length - 1), 'scale': 'minor'};
    }
    // Default to major
    return {'root': key, 'scale': 'major'};
  }

  static List<String> get availableKeys {
      final keys = <String>{};
      // Use a consistent set of 12 notes to generate keys
      const rootNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
      for (var note in rootNotes) {
          keys.add(note); // Major
          keys.add('${note}m'); // minor
      }
      return keys.toList()..sort();
  }

  static List<String> _generateScale(String key) {
    final keyInfo = parseKey(key);
    final root = keyInfo['root']!;
    final scaleType = keyInfo['scale']!;

    final useSharps = _sharpKeys.contains(root) || (!root.contains('b') && root.length == 1);
    final chromaticScale = useSharps ? _notesSharp : _notesFlat;
    
    int startIndex = chromaticScale.indexWhere((note) => note.toLowerCase() == root.toLowerCase());
    if (startIndex == -1) {
      // Fallback for keys not in the sharp/flat lists, e.g. 'Fb'
      startIndex = _notesFlat.indexWhere((note) => note.toLowerCase() == root.toLowerCase());
       if (startIndex == -1) throw FormatException('Invalid key: $key DU KEK implement');
    }

    final intervals = _scaleIntervals[scaleType]!;
    List<String> scaleNotes = [];

    for (int interval in intervals) {
      final noteIndex = (startIndex + interval) % 12;
      scaleNotes.add(chromaticScale[noteIndex]);
    }

    return scaleNotes;
  }

  /// Applies a flat 'b' or sharp '#' to a given note.
  static String _applyAccidental(String note, String accidental) {
    if (accidental.isEmpty) return note;

    // Find the note in both sharp and flat scales to get its index
    int index = _notesSharp.indexOf(note);
    if (index == -1) index = _notesFlat.indexOf(note);
    if (index == -1) return note; // Should not happen with valid notes

    // Apply the accidental
    if (accidental == 'b') {
      index = (index - 1 + 12) % 12; // +12 to handle negative results
    } else if (accidental == '#') {
      index = (index + 1) % 12;
    }

    // Prefer sharp or flat notation based on the original note
    return note.contains('b') ? _notesFlat[index] : _notesSharp[index];
  }


  /// Parse a chord into its components
  static Map<String, String> parseChordComponents(String chord) {
    Map<String, String> components = {
      'root': '',
      'quality': '',
      'extension': '',
      'modifier': '',
      'bass': ''
    };

    // Handle "N.C." (No Chord)
    if (chord == "N.C.") {
      components['root'] = "N.C.";
      return components;
    }

    String mainChord = chord;

    // Handle slash chords
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      mainChord = parts[0].trim();
      if (parts.length > 1) {
        String bassNote = parts[1].trim();
        // Validate bass note
        if (_bassNotePattern.hasMatch(bassNote)) {
          components['bass'] = '/$bassNote';
        }
      }
    }

    // Now parse the main chord part (without bass)
    final match = _chordPattern.firstMatch(mainChord);
    if (match != null) {
      components['root'] = match.group(1) ?? '';
      components['quality'] = match.group(2) ?? '';
      components['extension'] = match.group(3) ?? '';
      components['modifier'] = match.group(4) ?? '';
    } else {
      // Fallback: try to extract just the root
      final rootMatch = RegExp(r'^([A-Ga-g][#b]?)').firstMatch(mainChord);
      if (rootMatch != null) {
        components['root'] = rootMatch.group(1)!;
        if (mainChord.length > components['root']!.length) {
          components['modifier'] =
              mainChord.substring(components['root']!.length);
        }
      } else {
        components['root'] = mainChord;
      }
    }

    return components;
  }

  /// Parse a Nashville number into its components
  static Map<String, String> parseNashvilleComponents(String nashville) {
    Map<String, String> components = {
      'number': '',
      'quality': '',
      'extension': '',
      'modifier': '',
      'bass': ''
    };

    if (nashville == "N.C.") {
      components['number'] = "N.C.";
      return components;
    }

    // Handle slash chords first
    if (nashville.contains('/')) {
      List<String> parts = nashville.split('/');
      nashville = parts[0];
      if (parts.length > 1) {
        components['bass'] = '/${parts[1]}';
      }
    }

    // Use regex to find the number part, which could be e.g., "b7" or "#4" or "5"
    final numberMatch = RegExp(r'^([b#]?\d)').firstMatch(nashville);
    if (numberMatch == null) {
      return components; // Not a valid Nashville string
    }

    components['number'] = numberMatch.group(1)!;
    String remaining = nashville.substring(components['number']!.length);

    // Now, use the regex on the *rest* of the string
    final qualityPattern = RegExp(r'^(m|maj|min|aug|dim|sus|add|\+|°|ø|-)?(\d+)?(.*)');
    final match = qualityPattern.firstMatch(remaining);

    if (match != null) {
      components['quality'] = match.group(1) ?? '';
      components['extension'] = match.group(2) ?? '';
      components['modifier'] = match.group(3) ?? '';
    }

    return components;
  }

  /// Convert a Nashville number to a standard chord in the specified key
  static String nashvilleToChord(String nashvilleNumber, String key) {
    if (nashvilleNumber == "N.C." || key.isEmpty) {
      return nashvilleNumber;
    }

    final keyInfo = parseKey(key);
    final scale = _generateScale(key);
    if (scale.isEmpty) {
      return nashvilleNumber; // Return original if key is invalid
    }

    // Handle slash chords recursively
    if (nashvilleNumber.contains('/')) {
      List<String> parts = nashvilleNumber.split('/');
      if (parts.length == 2) {
        String baseNashville = parts[0].trim();
        String bassNashville = parts[1].trim();
        // The bass part of a Nashville chord is just a number, so we convert it directly
        String baseChord = nashvilleToChord(baseNashville, key);
        String bassChord = nashvilleToChord(bassNashville, key);
        // The result of converting a simple number (like '5') will be just the note name ('G')
        return "$baseChord/$bassChord";
      }
    }

    var components = parseNashvilleComponents(nashvilleNumber);
    String numberStr = components['number'] ?? '';
    if (numberStr.isEmpty) return nashvilleNumber; // Invalid Nashville format

    String accidental = '';
    if (numberStr.startsWith('b') || numberStr.startsWith('#')) {
      accidental = numberStr[0];
      numberStr = numberStr.substring(1);
    }

    int number = int.tryParse(numberStr) ?? 0;
    if (number < 1 || number > 7) {
      return nashvilleNumber; // Not a valid Nashville number
    }

    // Get the root note from the generated scale (number - 1 for 0-based index)
    String rootNote = scale[number - 1];

    // Apply the accidental if one was present (e.g., for "b7")
    if (accidental.isNotEmpty) {
      rootNote = _applyAccidental(rootNote, accidental);
    }

    // Determine the quality
    String quality = components['quality'] ?? '';
    String extension = components['extension'] ?? '';
    String modifier = components['modifier'] ?? '';

    // If no quality is specified, use the default for that scale degree
    if (quality.isEmpty && extension.isEmpty && accidental.isEmpty) {
      final qualities = keyInfo['scale'] == 'minor' ? _minorScaleQualities : _majorScaleQualities;
      quality = qualities[number - 1];
    } else if (quality == '-') {
      quality = 'm'; // Convert Nashville minor '-' to standard 'm'
    }

    // Handle 'M' for major chords in minor scales, which just means no quality symbol
    if (quality == 'M') {
      quality = '';
    }

    return '$rootNote$quality$extension$modifier';
  }


 static String chordToNashville(String chord, String key) {
    if (chord == "N.C." || key.isEmpty) {
      return chord;
    }

    final keyInfo = parseKey(key);
    final scale = _generateScale(key);
    if (scale.isEmpty) {
      return chord; // Return original if key is invalid
    }
    // Create a reverse map for easy lookup
    final noteToNumberMap = {for (var i = 0; i < scale.length; i++) scale[i].toLowerCase(): (i + 1).toString()};


    // Handle slash chords
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      if (parts.length == 2) {
        String basePart = parts[0].trim();
        String bassPart = parts[1].trim();
        String baseNashville = chordToNashville(basePart, key);
        // For the bass part, we only care about the number, not the quality
        String bassNashvilleNum = chordToNashville(bassPart, key).replaceAll(RegExp(r'[^b#\d]'), '');
        return "$baseNashville/$bassNashvilleNum";
      }
    }

    var components = parseChordComponents(chord);
    String root = components['root'] ?? '';
    if (root.isEmpty) return chord;

    String rootLower = root.toLowerCase();
    String? nashvilleNumber;
    String accidentalPrefix = '';

    // Find the Nashville number for the root note
    if (noteToNumberMap.containsKey(rootLower)) {
      nashvilleNumber = noteToNumberMap[rootLower];
    } else {
      // It's a chromatic note, find the nearest scale degree and add a flat/sharp
      int noteIndex = _notesSharp.indexOf(root);
      if (noteIndex == -1) noteIndex = _notesFlat.indexOf(root);
      if (noteIndex == -1) return chord; // Not a valid note

      for (var i = 0; i < scale.length; i++) {
        int scaleNoteIndex = _notesSharp.indexOf(scale[i]);
        if (scaleNoteIndex == -1) scaleNoteIndex = _notesFlat.indexOf(scale[i]);
        
        if ((noteIndex + 1) % 12 == scaleNoteIndex) {
          accidentalPrefix = 'b';
          nashvilleNumber = (i + 1).toString();
          break;
        }
        if ((noteIndex - 1 + 12) % 12 == scaleNoteIndex) {
          accidentalPrefix = '#';
          nashvilleNumber = (i + 1).toString();
          break;
        }
      }
    }

    if (nashvilleNumber == null) {
      return chord; // Root note not in the key or chromatically related
    }

    // Convert quality
    String quality = components['quality'] ?? '';
    String extension = components['extension'] ?? '';
    String modifier = components['modifier'] ?? '';

    // Check if the chord's quality is the default for its scale degree
    int number = int.parse(nashvilleNumber);
    // Only check default quality if it's a diatonic chord (no accidental)
    if (accidentalPrefix.isEmpty) {
      final qualities = keyInfo['scale'] == 'minor' ? _minorScaleQualities : _majorScaleQualities;
      String defaultQuality = qualities[number - 1];
      
      // Handle 'M' for major chords in minor scales
      if (defaultQuality == 'M') defaultQuality = '';

      if (quality == defaultQuality) {
        quality = ''; // If it's the default, we don't need to specify it in Nashville
      }
    }
    
    if (quality == 'm' || quality == 'min') {
      quality = '-';
    }

    return '$accidentalPrefix$nashvilleNumber$quality$extension$modifier';
  }

  static bool isPotentialChordToken(String token) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return false;
    }
    if (trimmedToken == "N.C.") {
      return true;
    }

    // Handle slash chords separately
    if (trimmedToken.contains('/')) {
      List<String> parts = trimmedToken.split('/');
      if (parts.length == 2) {
        String mainChord = parts[0].trim();
        String bassNote = parts[1].trim();

        return _chordPattern.hasMatch(mainChord) &&
            _bassNotePattern.hasMatch(bassNote);
      }
    }

    return _chordPattern.hasMatch(trimmedToken);
  }

  static List<String> extractChordsFromLine(String line) {
    List<String> chords = [];

    final tokens = line.split(RegExp(r'\s+'));

    for (String token in tokens) {
      if (isPotentialChordToken(token)) {
        chords.add(token.trim());
      }
    }

    return chords;
  }
}
