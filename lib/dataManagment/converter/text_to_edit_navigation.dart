import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/Pages/edit/page.dart';

/// Utility function to directly navigate from raw text to the edit page
/// This bypasses the InteractiveConverterPage entirely
class TextToEditNavigation {
  /// Navigate directly to edit page with raw text conversion
  /// This replaces the need for InteractiveConverterPage
  static Future<void> navigateToEditFromRawText({
    required BuildContext context,
    required String rawText,
    required String initialTitle,
    List<String> initialAuthors = const [],
    String? group,
  }) async {
    // Navigate directly to SongEditPage with raw text constructor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditPage.fromRawText(
          rawText: rawText,
          initialTitle: initialTitle,
          initialAuthors: initialAuthors,
          group: group,
        ),
      ),
    );
  }

  /// Static method to replace InteractiveConverterPage usage
  /// Call this instead of navigating to InteractiveConverterPage
  static void convertAndEdit({
    required BuildContext context,
    required String rawText,
    required String initialTitle,
    List<String> initialAuthors = const [],
    String? group,
  }) {
    navigateToEditFromRawText(
      context: context,
      rawText: rawText,
      initialTitle: initialTitle,
      initialAuthors: initialAuthors,
      group: group,
    );
  }
}
