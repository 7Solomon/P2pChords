// styles.dart
import 'package:flutter/material.dart';

class QuickSelectStyles {
  // Colors
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color accentColor = Color(0xFFFF4081);
  static const Color backgroundColor = Color(0xFF303030);
  static const Color selectedTextColor = Colors.white;
  static const Color unselectedTextColor = Color(0xFFBBBBBB);

  // Text Styles
  static const TextStyle selectedItemText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: selectedTextColor,
  );

  static const TextStyle itemText = TextStyle(
    fontSize: 16,
    color: unselectedTextColor,
  );

  // Decoration
  static final BoxDecoration wheelContainer = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 15,
        spreadRadius: 5,
      ),
    ],
  );

  static final BoxDecoration selectedItemHighlight = BoxDecoration(
    color: primaryColor.withOpacity(0.2),
    border: const Border(
      top: BorderSide(color: accentColor, width: 1),
      bottom: BorderSide(color: accentColor, width: 1),
    ),
  );
}
