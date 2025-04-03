import 'package:flutter/material.dart';

class UIStyle {
  // Colors
  static const Color primary = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color text = Color(0xFF121212);
  static const Color textLight = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFDCDCDC);

  // Text Styles
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: text,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: textLight,
  );

  // Button Styles
  static final ButtonStyle button = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    foregroundColor: primary,
    backgroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: primary),
    ),
  );

  static final ButtonStyle iconButton = IconButton.styleFrom(
    foregroundColor: primary,
    backgroundColor: Colors.transparent,
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: surface,
      labelStyle: caption,
    );
  }

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Spacing
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;

  // Padding
  static const EdgeInsets contentPadding = EdgeInsets.all(spacing);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing);
}
