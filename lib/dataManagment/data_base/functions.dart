import 'dart:convert';
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
  try {
    print('Using server URL: $serverUrl');

    // Get the file list from the server
    final fileList = await getFilesFromServer(serverUrl: serverUrl);

    if (fileList == null || fileList.isEmpty) {
      print('No files found on the server or failed to list files');
      return null;
    }

    print('Found ${fileList.length} files on the server');

    // Only process JSON files
    final jsonFiles = fileList
        .where(
            (file) => file['name'].toString().toLowerCase().endsWith('.json'))
        .toList();

    if (jsonFiles.isEmpty) {
      print('No JSON files found on the server');
      return null;
    }

    print('Found ${jsonFiles.length} JSON files to process');
    List<Song> songs = [];
    // Process each JSON file
    for (final file in jsonFiles) {
      final fileUrl = file['url'] as String;
      final fileName = file['name'] as String;

      final song = await fetchSongFromServer(
        fileUrl: fileUrl,
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
}) async {
  try {
    // Remove trailing slash if present
    final baseUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    // Assuming the server provides a file list endpoint
    final listEndpoint = '$baseUrl/files';

    final response = await http.get(Uri.parse(listEndpoint));

    if (response.statusCode == 200) {
      try {
        // Parse the JSON response
        final List<dynamic> files = json.decode(response.body);
        return files.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing server response: $e');
        return null;
      }
    } else {
      print('Server returned status code: ${response.statusCode}');
      // Fallback for testing
      return [
        {
          'url': '$baseUrl/songs.json',
          'name': 'songs.json',
          'mimeType': 'application/json'
        },
      ];
    }
  } catch (e) {
    print('Error accessing server: $e');
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
  required String fileUrl,
  int timeoutSeconds = 10,
}) async {
  try {
    print('Downloading file: $fileUrl');

    // Make the HTTP request with timeout
    final response = await http
        .get(Uri.parse(fileUrl))
        .timeout(Duration(seconds: timeoutSeconds));

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Check if we got HTML instead of JSON
      if (response.body.trim().startsWith('<')) {
        print('Received HTML response instead of JSON.');
        return null;
      }

      print('Successfully downloaded file, parsing JSON...');

      // Parse the JSON response
      final Map<String, dynamic> jsonData = json.decode(response.body);

      // Create a Song object from the parsed JSON
      return Song.fromMap(jsonData);
    } else {
      // Handle different HTTP error codes
      print('Failed to load song data. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    // Handle specific exceptions with more detailed error messages
    if (e is http.ClientException) {
      print('Network error: $e');
    } else if (e is FormatException) {
      print('Error parsing JSON data: $e');
    } else {
      print('Error fetching song data: $e');
    }
    return null;
  }
}
