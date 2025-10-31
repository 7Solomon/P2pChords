import 'package:flutter/material.dart';

class QuickSelectStyles {
  // Modern, clean colors matching your app's theme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color lightText = Color(0xFF757575);
  static const Color white = Colors.white;
  static const Color overlayBackground = Color(0xF0FAFAFA);

  // Text Styles with better hierarchy
  static const TextStyle selectedItemText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryBlue,
    letterSpacing: 0.3,
  );

  static const TextStyle itemText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: lightText,
    letterSpacing: 0.2,
  );

  static const TextStyle headerText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: lightText,
    letterSpacing: 1.2,
  );

  // Modern wheel container with subtle shadow and gradient
  static final BoxDecoration wheelContainer = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 30,
        spreadRadius: 0,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: primaryBlue.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: -5,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // Selected item highlight with gradient
  static final BoxDecoration selectedItemHighlight = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        lightBlue.withOpacity(0.3),
        lightBlue.withOpacity(0.5),
        lightBlue.withOpacity(0.3),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryBlue.withOpacity(0.3),
      width: 1.5,
    ),
  );

  // Add a subtle indicator dot
  static Widget buildSelectionIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: primaryBlue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}