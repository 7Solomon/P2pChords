import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerUtil {
  /// Opens file picker and loads a song JSON file
  static Future<Song?> pickSongFile(
    BuildContext context,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && context.mounted) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        // Validate JSON and convert to Song
        Map<String, dynamic> jsonData = jsonDecode(content);
        Song loadedSong = Song.fromMap(jsonData);

        return loadedSong;
      }
      return null;
    } catch (e) {
      SnackService().showError('Fehler beim Laden der Datei: ${e.toString()}');
      return null;
    }
  }
}
