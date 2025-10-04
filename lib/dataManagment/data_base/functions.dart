import 'dart:convert';
import 'package:P2pChords/networking/auth.dart';
import 'package:P2pChords/networking/services/notification_service.dart';
import 'package:http/http.dart' as http;
import '../data_class.dart';

/// Fetches all JSON files from a custom server and merges the song data
///
/// Parameters:
/// - [serverUrl]: The custom server URL
/// - [timeoutSeconds]: Maximum time to wait for each request
///
/// Returns:
/// - A list of Song objects if successful, or null if an error occurred
Future<List<Song>?> fetchSongDataFromServer({
  required String serverUrl,
  int timeoutSeconds = 15,
}) async {
  final tokenManager = ApiTokenManager();
  try {
    final fileList = await getFilesFromServer(
        serverUrl: serverUrl, tokenManager: tokenManager);

    if (fileList == null || fileList.isEmpty) {
      print('No files found on the server or failed to list files');
      return null;
    }
    // Only process JSON files
    final jsonFiles = fileList
        .where((file) =>
            file['filename'].toString().toLowerCase().endsWith('.json'))
        .toList();

    if (jsonFiles.isEmpty) {
      print('No JSON files found on the server');
      return null;
    }

    List<Song> songs = [];
    for (final file in jsonFiles) {
      final fileName = file['filename'] as String;
      final name = file['name'] as String;

      final song = await fetchSongFromServer(
        baseUrl: serverUrl,
        fileUrl: fileName,
        tokenManager: tokenManager,
        timeoutSeconds: timeoutSeconds,
      );
      if (song == null) {
        continue;
      }
      songs.add(song);
    }
    return songs;
  } catch (e) {
    print('Error fetching song data from server: $e');
    return null;
  }
}

/// Gets files from a custom server using direct HTTP requests
///
/// Parameters:
/// - [serverUrl]: The server URL where files are located
///
/// Returns:
/// - A List of file metadata objects if successful, or null if an error occurred
Future<List<Map<String, dynamic>>?> getFilesFromServer({
  required String serverUrl,
  required ApiTokenManager tokenManager,
  int timeoutSeconds = 30,
}) async {
  try {
        String correctedUrl = serverUrl;
    if (!correctedUrl.startsWith('http://') && !correctedUrl.startsWith('https://')) {
      correctedUrl = 'http://$correctedUrl';
    }

    // Remove trailing slash if present
    final baseUrl = correctedUrl.endsWith('/')
        ? correctedUrl.substring(0, correctedUrl.length - 1)
        : correctedUrl;

    // Assuming the server provides a file list endpoint
    final listEndpoint = '$baseUrl/api/song_data/files';

    final String? authToken = await tokenManager.getToken('serverApiToken');
    Map<String, String> headers = {};

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
      print('Using auth token: $authToken');  
    } else {
      print('No authorization token found');
      NotificationService()
          .showError('Du hast keinen Token gespeichert. Bitte erstelle einen.');
    }

    final response = await http
        .get(Uri.parse(listEndpoint), headers: headers)
        .timeout(Duration(seconds: timeoutSeconds));
    print('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> files = json.decode(response.body)['files'];
        print('Fetched files: ${files.map((f) => f['filename']).toList()}');
        return files.cast<Map<String, dynamic>>();
      } catch (e) {
        return null;
      }
    } else {
      print('Failed to fetch files. Status code: ${response.statusCode}');
      NotificationService().showError('Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error in getFilesFromServer: $e');
    NotificationService().showError('Error: $e');
    return null;
  }
}

/// Fetches Song from a JSON file hosted on the custom server.
///
/// Parameters:
/// - [fileUrl]: The URL to the JSON file
/// - [timeoutSeconds]: Maximum time to wait for the request
///
/// Returns:
/// - A [Song] object if successful, or null if an error occurred
Future<Song?> fetchSongFromServer({
  required String baseUrl,
  required String fileUrl,
  required ApiTokenManager tokenManager,
  int timeoutSeconds = 10,
}) async {
  try {
    // Retrieve the token
    final String? authToken = await tokenManager.getToken('serverApiToken');
    Map<String, String> headers = {};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    } else {
      NotificationService()
          .showError('Du hast keinen Token gespeichert. Bitte erstelle einen.');
    }

    final response = await http
        .get(Uri.parse('$baseUrl/api/song_data/$fileUrl'), headers: headers)
        .timeout(Duration(seconds: timeoutSeconds));

    if (response.statusCode == 200) {
      if (response.body.trim().startsWith('<')) {
        NotificationService()
            .showError('Received HTML response instead of JSON.');
        return null;
      }

      // Parse the JSON response
      final Map<String, dynamic> jsonData = json.decode(response.body);

      // Create a Song object from the parsed JSON
      return Song.fromMap(jsonData);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      NotificationService().showError(
          'Authorization error: Status code ${response.statusCode}. Token might be invalid or missing.');
      // Optionally, you could try to refresh the token or prompt for login here.
      return null;
    } else {
      // Handle different HTTP error codes
      NotificationService().showError(
          'Failed to load song data. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    // Handle specific exceptions with more detailed error messages
    if (e is http.ClientException) {
      NotificationService().showError('Network error: $e');
    } else if (e is FormatException) {
      NotificationService().showError('Error parsing JSON data: $e');
    } else {
      NotificationService().showError('Error fetching song data: $e');
    }
    return null;
  }
}
