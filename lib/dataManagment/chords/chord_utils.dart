class ChordUtils {
  static const List<String> _sharpKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#'];
  static const List<String> _flatKeys = ['F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb'];
  
  static const List<String> _notesSharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const List<String> _notesFlat = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  static const Map<String, List<int>> _scaleIntervals = {
    'major': [0, 2, 4, 5, 7, 9, 11],
    'minor': [0, 2, 3, 5, 7, 8, 10],
  };

  static const List<String> _majorScaleQualities = ['', 'm', 'm', '', '', 'm', 'dim'];
  static const List<String> _minorScaleQualities = ['m', 'dim', '', 'm', 'm', '', ''];

  static final RegExp _bassNotePattern = RegExp(r'^[A-Ga-g][#b]?$');

  static final RegExp _chordPattern = RegExp(
    r'^([A-Ga-g][#b]?)' // Root note
    r'(m|maj|min|aug|dim|sus|add|\+|°|ø|-)?' // Quality/type
    r'(\d+)?' // Number/extension (7, 9, etc.)
    r'(sus\d+|add\d+|aug|dim|\+|\(.*?\))*' // Additional modifiers
    r'(\*)?$' // Optional trailing asterisk
  );

  static Map<String, String> parseKey(String key) {
    if (key.endsWith('m') && !key.endsWith('dim') && key.length > 1) {
      return {'root': key.substring(0, key.length - 1), 'scale': 'minor'};
    }
    return {'root': key, 'scale': 'major'};
  }

  // FIXED: Use proper sharp/flat convention
  static List<String> get availableKeys {
    final keys = <String>[];
    
    // Sharp keys (major)
    for (var key in _sharpKeys) {
      keys.add(key);
      keys.add('${key}m');
    }
    
    // Flat keys (major) - excluding C which is already in sharp keys
    for (var key in _flatKeys) {
      if (key != 'C') {
        keys.add(key);
        keys.add('${key}m');
      }
    }
    
    return keys..sort();
  }

  static List<String> _generateScale(String key) {
    final keyInfo = parseKey(key);
    final root = keyInfo['root']!;
    final scaleType = keyInfo['scale']!;

    // Use sharp notation for sharp keys, flat for flat keys
    final useSharps = _sharpKeys.contains(root);
    final chromaticScale = useSharps ? _notesSharp : _notesFlat;
    
    int startIndex = chromaticScale.indexWhere((note) => note.toLowerCase() == root.toLowerCase());
    if (startIndex == -1) {
      // Try the other chromatic scale
      final altChromaticScale = useSharps ? _notesFlat : _notesSharp;
      startIndex = altChromaticScale.indexWhere((note) => note.toLowerCase() == root.toLowerCase());
      if (startIndex == -1) {
        throw FormatException('Invalid key: $key');
      }
      return _generateScaleFromIndex(startIndex, scaleType, altChromaticScale);
    }

    return _generateScaleFromIndex(startIndex, scaleType, chromaticScale);
  }

  static List<String> _generateScaleFromIndex(int startIndex, String scaleType, List<String> chromaticScale) {
    final intervals = _scaleIntervals[scaleType]!;
    List<String> scaleNotes = [];

    for (int interval in intervals) {
      final noteIndex = (startIndex + interval) % 12;
      scaleNotes.add(chromaticScale[noteIndex]);
    }

    return scaleNotes;
  }

  static String _applyAccidental(String note, String accidental) {
    if (accidental.isEmpty) return note;

    int index = _notesSharp.indexOf(note);
    if (index == -1) index = _notesFlat.indexOf(note);
    if (index == -1) return note;

    if (accidental == 'b') {
      index = (index - 1 + 12) % 12;
    } else if (accidental == '#') {
      index = (index + 1) % 12;
    }

    return note.contains('b') ? _notesFlat[index] : _notesSharp[index];
  }

  static Map<String, String> parseChordComponents(String chord) {
    Map<String, String> components = {
      'root': '',
      'quality': '',
      'extension': '',
      'modifier': '',
      'bass': ''
    };

    if (chord == "N.C.") {
      components['root'] = "N.C.";
      return components;
    }

    String mainChord = chord;

    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      mainChord = parts[0].trim();
      if (parts.length > 1) {
        String bassNote = parts[1].trim();
        if (_bassNotePattern.hasMatch(bassNote)) {
          components['bass'] = '/$bassNote';
        }
      }
    }

    final match = _chordPattern.firstMatch(mainChord);
    if (match != null) {
      components['root'] = match.group(1) ?? '';
      components['quality'] = match.group(2) ?? '';
      components['extension'] = match.group(3) ?? '';
      components['modifier'] = match.group(4) ?? '';
    } else {
      final rootMatch = RegExp(r'^([A-Ga-g][#b]?)').firstMatch(mainChord);
      if (rootMatch != null) {
        components['root'] = rootMatch.group(1)!;
        if (mainChord.length > components['root']!.length) {
          components['modifier'] = mainChord.substring(components['root']!.length);
        }
      } else {
        components['root'] = mainChord;
      }
    }

    return components;
  }

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

  if (nashville.contains('/')) {
    List<String> parts = nashville.split('/');
    nashville = parts[0];
    if (parts.length > 1) {
      components['bass'] = '/${parts[1]}';
    }
  }

  final numberMatch = RegExp(r'^([b#]?[1-7])').firstMatch(nashville);
  if (numberMatch == null) {
    return components;
  }

  components['number'] = numberMatch.group(1)!;
  String remaining = nashville.substring(components['number']!.length);

  // FIXED: Better pattern that handles 'add9', 'sus4', etc. as modifiers, not quality
  // Match quality (without 'add' or 'sus' since those need numbers)
  final qualityPattern = RegExp(r'^(m|maj|min|aug|dim|-|°|ø|\+)?');
  final qualityMatch = qualityPattern.firstMatch(remaining);
  
  if (qualityMatch != null && qualityMatch.group(1) != null) {
    components['quality'] = qualityMatch.group(1)!;
    remaining = remaining.substring(qualityMatch.group(0)!.length);
  }

  // Now check for extension (standalone number like '7', '9')
  final extensionPattern = RegExp(r'^(\d+)');
  final extensionMatch = extensionPattern.firstMatch(remaining);
  
  if (extensionMatch != null) {
    components['extension'] = extensionMatch.group(1)!;
    remaining = remaining.substring(extensionMatch.group(0)!.length);
  }

  // Everything else is modifier (add9, sus4, etc.)
  if (remaining.isNotEmpty) {
    components['modifier'] = remaining;
  }

  return components;
}
  // FIXED: Apply default quality even when extension is present
  static String nashvilleToChord(String nashvilleNumber, String key) {
    if (nashvilleNumber == "N.C." || key.isEmpty) {
      return nashvilleNumber;
    }

    final keyInfo = parseKey(key);
    final scale = _generateScale(key);
    if (scale.isEmpty) {
      return nashvilleNumber;
    }

    // Handle slash chords recursively
    if (nashvilleNumber.contains('/')) {
      List<String> parts = nashvilleNumber.split('/');
      if (parts.length == 2) {
        String baseNashville = parts[0].trim();
        String bassNashville = parts[1].trim();
        String baseChord = nashvilleToChord(baseNashville, key);
        
        // FIXED: For bass notes, just get the root note without quality
        String bassChord = _nashvilleToBassNote(bassNashville, key);
        return "$baseChord/$bassChord";
      }
    }

    var components = parseNashvilleComponents(nashvilleNumber);
    String numberStr = components['number'] ?? '';
    if (numberStr.isEmpty) return nashvilleNumber;

    String accidental = '';
    if (numberStr.startsWith('b') || numberStr.startsWith('#')) {
      accidental = numberStr[0];
      numberStr = numberStr.substring(1);
    }

    int number = int.tryParse(numberStr) ?? 0;
    if (number < 1 || number > 7) {
      return nashvilleNumber;
    }

    String rootNote = scale[number - 1];

    if (accidental.isNotEmpty) {
      rootNote = _applyAccidental(rootNote, accidental);
    }

    String quality = components['quality'] ?? '';
    String extension = components['extension'] ?? '';
    String modifier = components['modifier'] ?? '';

    // FIXED: Apply default quality if no explicit quality is given (regardless of extension)
    if (quality.isEmpty && accidental.isEmpty) {
      final qualities = keyInfo['scale'] == 'minor' ? _minorScaleQualities : _majorScaleQualities;
      quality = qualities[number - 1];
    } else if (quality == '-') {
      quality = 'm';
    }

    if (quality == 'M') {
      quality = '';
    }

    return '$rootNote$quality$extension$modifier';
  }

  // NEW: Helper to convert Nashville to just the bass note (no quality)
  static String _nashvilleToBassNote(String nashvilleNumber, String key) {
    final keyInfo = parseKey(key);
    final scale = _generateScale(key);
    if (scale.isEmpty) {
      return nashvilleNumber;
    }

    var components = parseNashvilleComponents(nashvilleNumber);
    String numberStr = components['number'] ?? '';
    if (numberStr.isEmpty) return nashvilleNumber;

    String accidental = '';
    if (numberStr.startsWith('b') || numberStr.startsWith('#')) {
      accidental = numberStr[0];
      numberStr = numberStr.substring(1);
    }

    int number = int.tryParse(numberStr) ?? 0;
    if (number < 1 || number > 7) {
      return nashvilleNumber;
    }

    String rootNote = scale[number - 1];

    if (accidental.isNotEmpty) {
      rootNote = _applyAccidental(rootNote, accidental);
    }

    // Return ONLY the root note for bass notes
    return rootNote;
  }

  static String chordToNashville(String chord, String key) {
    if (chord == "N.C." || key.isEmpty) {
      return chord;
    }

    final keyInfo = parseKey(key);
    final scale = _generateScale(key);
    if (scale.isEmpty) {
      return chord;
    }

    final noteToNumberMap = {for (var i = 0; i < scale.length; i++) scale[i].toLowerCase(): (i + 1).toString()};

    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      if (parts.length == 2) {
        String basePart = parts[0].trim();
        String bassPart = parts[1].trim();
        String baseNashville = chordToNashville(basePart, key);
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

    if (noteToNumberMap.containsKey(rootLower)) {
      nashvilleNumber = noteToNumberMap[rootLower];
    } else {
      int noteIndex = _notesSharp.indexOf(root);
      if (noteIndex == -1) noteIndex = _notesFlat.indexOf(root);
      if (noteIndex == -1) return chord;

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
      return chord;
    }

    String quality = components['quality'] ?? '';
    String extension = components['extension'] ?? '';
    String modifier = components['modifier'] ?? '';

    int number = int.parse(nashvilleNumber);
    if (accidentalPrefix.isEmpty) {
      final qualities = keyInfo['scale'] == 'minor' ? _minorScaleQualities : _majorScaleQualities;
      String defaultQuality = qualities[number - 1];
      
      if (defaultQuality == 'M') defaultQuality = '';

      if (quality == defaultQuality) {
        quality = '';
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

    String mainChord = trimmedToken;
    String? bassNote;
    
    if (trimmedToken.contains('/')) {
      List<String> parts = trimmedToken.split('/');
      if (parts.length != 2) return false;
      
      mainChord = parts[0].trim();
      bassNote = parts[1].trim();
      
      if (!_chordPattern.hasMatch(mainChord)) return false;
      if (!_bassNotePattern.hasMatch(bassNote)) return false;
      
      return true;
    }

    return _chordPattern.hasMatch(mainChord);
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