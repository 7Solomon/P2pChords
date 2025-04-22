import 'dart:convert';
import 'package:flutter/material.dart';

/// Utility class for chord operations and Nashville number system conversions
class ChordUtils {
  static Map<String, Map<String, String>>? _nashvilleMappings;
  static bool _initialized = false;

  // Enhanced chord pattern to recognize various parts of a chord including complex chords
  static final RegExp _chordPattern = RegExp(r'^([A-Ga-g][#b]?)' // Root note
      r'(m|maj|min|aug|dim|sus|add|\+|°|ø|-)?' // Quality/type
      r'(\d+)?' // Number/extension (7, 9, etc.)
      r'(sus\d+|add\d+|aug|dim|\+|\(.*?\))?' // Additional modifiers/parenthetical
      r'(\/[A-Ga-g][#b]?)?' // Optional bass note
      r'$');

  // Enhanced Nashville pattern to recognize various parts of a Nashville chord
  static final RegExp _nashvillePattern = RegExp(r'^(\d+)' // Number
      r'(-|maj|min|aug|dim|sus|add|\+|°|ø)?' // Quality/type
      r'(\d+)?' // Extension (7, 9, etc.)
      r'(sus\d+|add\d+|aug|dim|\+|\(.*?\))?' // Additional modifiers/parenthetical
      r'(\/\d+)?' // Optional bass note
      r'$');

  /// Initialize the chord mappings from assets
  static Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/nashville_to_chord_by_key.json');
    _nashvilleMappings = Map<String, Map<String, String>>.from(json
        .decode(jsonString)
        .map((key, value) => MapEntry(key, Map<String, String>.from(value))));
    _initialized = true;
  }

  /// Check if mappings are initialized
  static bool get isInitialized => _initialized;

  /// Get all supported keys
  static List<String> get availableKeys =>
      _checkInitialized() ? _nashvilleMappings?.keys.toList() ?? [] : [];

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

    // Handle slash chords
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      chord = parts[0];
      if (parts.length > 1) {
        components['bass'] = '/' + parts[1];
      }
    }

    // Try to match the chord pattern
    final match = _chordPattern.firstMatch(chord);
    if (match != null) {
      components['root'] = match.group(1) ?? '';

      // Handle quality modifiers
      String? quality = match.group(2);
      if (quality != null && quality.isNotEmpty) {
        components['quality'] = quality;
      }

      // Handle extensions
      String? extension = match.group(3);
      if (extension != null && extension.isNotEmpty) {
        components['extension'] = extension;
      }

      // Handle additional modifiers
      String? modifier = match.group(4);
      if (modifier != null && modifier.isNotEmpty) {
        components['modifier'] = modifier;
      }
    } else {
      // If the pattern doesn't match, try to extract just the root
      final rootMatch = RegExp(r'^([A-Ga-g][#b]?)').firstMatch(chord);
      if (rootMatch != null) {
        components['root'] = rootMatch.group(1)!;
        // Treat remaining characters as modifiers
        if (chord.length > components['root']!.length) {
          components['modifier'] = chord.substring(components['root']!.length);
        }
      } else {
        // If still no match, treat the whole string as the root
        components['root'] = chord;
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

    // Handle "N.C." (No Chord)
    if (nashville == "N.C.") {
      components['number'] = "N.C.";
      return components;
    }

    // Handle slash chords
    if (nashville.contains('/')) {
      List<String> parts = nashville.split('/');
      nashville = parts[0];
      if (parts.length > 1) {
        components['bass'] = '/' + parts[1];
      }
    }

    // Try to match the Nashville pattern
    final match = _nashvillePattern.firstMatch(nashville);
    if (match != null) {
      components['number'] = match.group(1) ?? '';

      // Handle quality modifiers
      String? quality = match.group(2);
      if (quality != null && quality.isNotEmpty) {
        components['quality'] = quality;
      }

      // Handle extensions
      String? extension = match.group(3);
      if (extension != null && extension.isNotEmpty) {
        components['extension'] = extension;
      }

      // Handle additional modifiers
      String? modifier = match.group(4);
      if (modifier != null && modifier.isNotEmpty) {
        components['modifier'] = modifier;
      }
    } else {
      // Extract the numerical part if possible
      final numberMatch = RegExp(r'^(\d+)').firstMatch(nashville);
      if (numberMatch != null) {
        components['number'] = numberMatch.group(1)!;
        if (nashville.length > numberMatch.group(1)!.length) {
          components['quality'] =
              nashville.substring(numberMatch.group(1)!.length);
        }
      } else {
        // If no match, treat the whole string as the number
        components['number'] = nashville;
      }
    }

    return components;
  }

  /// Convert a Nashville number to a standard chord in the specified key
  static String nashvilleToChord(String nashvilleNumber, String key) {
    if (!_checkInitialized()) {
      return nashvilleNumber; // Return unchanged if not initialized
    }

    if (nashvilleNumber == "N.C." || key.isEmpty) {
      return nashvilleNumber; // Return as-is for "No Chord" or if no key provided
    }

    // Handle slash chords
    if (nashvilleNumber.contains('/')) {
      List<String> parts = nashvilleNumber.split('/');
      if (parts.length == 2) {
        String baseNashville = parts[0].trim();
        String bassNashville = parts[1].trim();

        String baseChord = nashvilleToChord(baseNashville, key);
        String bassNote = "";

        // Convert the bass note
        if (RegExp(r'^\d+$').hasMatch(bassNashville)) {
          final keyMap = _nashvilleMappings?[key];
          if (keyMap != null) {
            bassNote = keyMap[bassNashville] ?? bassNashville;
          } else {
            bassNote = bassNashville;
          }
        } else {
          bassNote = nashvilleToChord(bassNashville, key);
        }

        return "$baseChord/$bassNote";
      }
    }

    // Parse the Nashville number into components
    var components = parseNashvilleComponents(nashvilleNumber);

    // If we can't parse properly or number is empty, use direct mapping fallback
    if (components['number']!.isEmpty) {
      return _directMappingFallback(nashvilleNumber, key);
    }

    // Get the root note from the Nashville number
    final keyMap = _nashvilleMappings?[key];
    if (keyMap == null) {
      return nashvilleNumber; // Return original if key mapping not found
    }

    String? rootNote = keyMap[components['number']];
    if (rootNote == null) {
      return _directMappingFallback(nashvilleNumber, key);
    }

    // Convert quality and build the chord
    String quality = components['quality'] ?? '';
    if (quality == '-') {
      quality = 'm';
    }

    // Assemble the chord
    String chord = rootNote + quality;

    // Add extension if present
    if (components['extension']?.isNotEmpty == true) {
      chord += components['extension']!;
    }

    // Add modifier if present
    if (components['modifier']?.isNotEmpty == true) {
      chord += components['modifier']!;
    }

    // Add bass note if present
    if (components['bass']?.isNotEmpty == true) {
      String bassNumber = components['bass']!.substring(1); // Remove the slash
      String? bassNote = keyMap[bassNumber];
      if (bassNote != null) {
        chord += '/' + bassNote;
      } else {
        // If direct mapping fails, try to interpret as a chord
        chord += components['bass']!;
      }
    }

    return chord;
  }

  // Use direct mapping as fallback for complex cases
  static String _directMappingFallback(String nashvilleNumber, String key) {
    // Try to extract just the number part
    final numberMatch = RegExp(r'^(\d+)').firstMatch(nashvilleNumber);
    if (numberMatch != null) {
      final number = numberMatch.group(1);
      final keyMap = _nashvilleMappings?[key];
      if (keyMap != null && number != null) {
        final rootNote = keyMap[number];
        if (rootNote != null) {
          // Add any modifiers after the number
          final remainingPart = nashvilleNumber.substring(number.length);
          String quality = remainingPart;
          if (quality == '-') {
            quality = 'm';
          }
          return rootNote + quality;
        }
      }
    }

    // If all else fails, return the original nashville number
    return nashvilleNumber;
  }

  /// Convert a standard chord to Nashville notation in the specified key
  static String chordToNashville(String chord, String key) {
    if (!_checkInitialized()) {
      return chord; // Return unchanged if not initialized
    }

    if (chord == "N.C." || key.isEmpty) {
      return chord; // Return as-is for "No Chord" or if no key provided
    }

    // Validation for songKey
    if (!RegExp(r'^[A-G][#b]?$').hasMatch(key)) {
      throw FormatException('Invalid key format: $key');
    }

    // Handle slash chords (e.g., "C/G")
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      if (parts.length == 2) {
        String basePart = parts[0].trim();
        String bassPart = parts[1].trim();

        // Get the Nashville number for the base chord
        String baseNashville = chordToNashville(basePart, key);

        // For the bass note, we need to find the Nashville number
        String bassRoot = bassPart.replaceAll(RegExp(r'[^A-Ga-g#b]'), '');
        String bassNashville = _getNashvilleNumberForRoot(bassRoot, key);

        return "$baseNashville/$bassNashville";
      }
    }

    // Parse the chord into components
    var components = parseChordComponents(chord);

    // Get the Nashville number for the root note
    String nashvilleNumber =
        _getNashvilleNumberForRoot(components['root'] ?? '', key);

    // Convert quality
    String quality = components['quality'] ?? '';
    if (quality == 'm' || quality == 'min') {
      quality = '-';
    }

    // Assemble the Nashville notation
    String nashville = nashvilleNumber + quality;

    // Add extension if present
    if (components['extension']?.isNotEmpty == true) {
      nashville += components['extension']!;
    }

    // Add modifier if present
    if (components['modifier']?.isNotEmpty == true) {
      nashville += components['modifier']!;
    }

    // Add bass note if present
    if (components['bass']?.isNotEmpty == true) {
      String bassNote = components['bass']!.substring(1); // Remove the slash
      String bassNashville = _getNashvilleNumberForRoot(bassNote, key);
      nashville += '/' + bassNashville;
    }

    return nashville;
  }

  /// Helper method to get Nashville number for a root note
  static String _getNashvilleNumberForRoot(String rootNote, String key) {
    if (rootNote.isEmpty) {
      throw const FormatException("Empty chord root");
    }

    String? nashvilleNumber;
    final keyMap = _nashvilleMappings?[key];

    if (keyMap != null) {
      keyMap.forEach((number, note) {
        if (note.toLowerCase() == rootNote.toLowerCase()) {
          nashvilleNumber = number;
        }
      });
    }

    if (nashvilleNumber == null) {
      throw FormatException("Invalid Chord Root: $rootNote");
    }

    return nashvilleNumber!;
  }

  /// Check if the ChordUtils has been properly initialized
  static bool _checkInitialized() {
    return _initialized && _nashvilleMappings != null;
  }
}
