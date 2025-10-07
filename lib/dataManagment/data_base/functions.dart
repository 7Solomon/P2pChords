import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/networking/auth.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../data_class.dart';

/// Fetches all JSON files from a custom server and merges the song data
Future<List<Song>?> fetchSongDataFromServer({
  required String serverUrl,
  int timeoutSeconds = 15,
}) async {
  final tokenManager = ApiTokenManager();
  try {
    // Normalize the base URL first
    String normalizedUrl = serverUrl;
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://$normalizedUrl';
    }
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    final fileList = await getFilesFromServer(
        serverUrl: normalizedUrl, tokenManager: tokenManager);

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
      // Use 'path' for the actual file location, 'filename' for display
      final filePath = file['path'] as String;
      final name = file['name'] as String;

      print('Fetching song: $name from path: $filePath');

      final song = await fetchSongFromServer(
        baseUrl: normalizedUrl, // Use normalized URL
        fileUrl: filePath,
        tokenManager: tokenManager,
      );
      
      if (song == null) {
        print('Failed to fetch song: $name');
        continue;
      }
      
      songs.add(song);
    }
    
    print('Successfully fetched ${songs.length} songs');
    return songs;
  } catch (e) {
    print('Error fetching song data from server: $e');
    return null;
  }
}

/// Gets files from a custom server using direct HTTP requests
Future<List<Map<String, dynamic>>?> getFilesFromServer({
  required String serverUrl,
  required ApiTokenManager tokenManager,
  int timeoutSeconds = 30,
}) async {
  try {
    // serverUrl should already be normalized by caller
    final listEndpoint = '$serverUrl/api/song_data/files';

    final String? authToken = await tokenManager.getToken('serverApiToken');
    Map<String, String> headers = {};

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
      print('Using auth token for file list');
    } else {
      print('No authorization token found');
      SnackService().showError('Kein Authentifizierungstoken gefunden');
    }

    print('Fetching file list from: $listEndpoint');

    final response = await http
        .get(Uri.parse(listEndpoint), headers: headers)
        .timeout(Duration(seconds: timeoutSeconds));

    print('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        final files = jsonData['files'] as List;
        print('Found ${files.length} files');
        return files.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing JSON response: $e');
        SnackService().showError('Fehler beim Parsen der Antwort');
        return null;
      }
    } else {
      print('Failed to fetch files. Status code: ${response.statusCode}');
      SnackService().showError('Server-Fehler: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error in getFilesFromServer: $e');
    SnackService().showError('Verbindungsfehler: $e');
    return null;
  }
}
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
      SnackService().showError('Kein Authentifizierungstoken');
    }

    // Normalize path separators for URL (Windows uses backslashes)
    final normalizedPath = fileUrl.replaceAll('\\', '/');
    
    // Encode each path segment separately to preserve the / separators
    final pathSegments = normalizedPath.split('/');
    final encodedSegments = pathSegments.map((segment) => Uri.encodeComponent(segment)).toList();
    final encodedPath = encodedSegments.join('/');
    
    // baseUrl should already include http:// from the caller
    final fullUrl = '$baseUrl/api/song_data/$encodedPath';
    
    print('Fetching song from: $fullUrl');

    final response = await http
        .get(Uri.parse(fullUrl), headers: headers)
        .timeout(Duration(seconds: timeoutSeconds));

    print('Song fetch response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Song.fromMap(jsonData);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      SnackService().showError('Zugriff verweigert');
      return null;
    } else {
      SnackService().showError('Fehler ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching song: $e');
    if (e is http.ClientException) {
      SnackService().showError('Netzwerkfehler');
    } else if (e is FormatException) {
      SnackService().showError('Ungültiges JSON-Format');
    } else {
      SnackService().showError('Fehler: $e');
    }
    return null;
  }
}

/// Uploads a song to the server
Future<bool> uploadSongToServer({
  required String serverUrl,
  required Song song,
  String? subfolder,
}) async {
  final tokenManager = ApiTokenManager();
  
  try {
    // Normalize the base URL
    String normalizedUrl = serverUrl;
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://$normalizedUrl';
    }
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    final uploadEndpoint = '$normalizedUrl/api/song_data';

    // Get admin token (upload requires admin privileges)
    final String? authToken = await tokenManager.getToken('serverApiToken');
    if (authToken == null || authToken.isEmpty) {
      SnackService().showError('Kein Admin-Token gefunden');
      print('No admin token found');
      return false;
    }

    // Prepare filename
    String authorName = song.header.authors.isNotEmpty 
        ? song.header.authors[0] 
        : 'Unknown';
    
    // Clean filename (remove special characters)
    String cleanName = song.header.name.replaceAll(RegExp(r'[^\w\s-]'), '');
    String cleanAuthor = authorName.replaceAll(RegExp(r'[^\w\s-]'), '');
    
    String filename = '${cleanName}_$cleanAuthor.json';
    
    // If subfolder is specified, prepend it to filename
    if (subfolder != null && subfolder.isNotEmpty) {
      filename = '$subfolder/$filename';
    }

    print('Uploading song: ${song.header.name} as $filename');

    // Convert song to JSON
    final songJson = song.toMap();
    final jsonString = jsonEncode(songJson);

    // Create multipart request
    var request = http.MultipartRequest('POST', Uri.parse(uploadEndpoint));
    
    // Add authorization header
    request.headers['Authorization'] = 'Bearer $authToken';
    
    // Add the JSON file as a multipart file
    request.files.add(
      http.MultipartFile.fromString(
        'file',
        jsonString,
        filename: filename,
        contentType: http_parser.MediaType('application', 'json'),
      ),
    );

    print('Sending upload request to: $uploadEndpoint');

    // Send request with longer timeout
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60), // Increased timeout
      onTimeout: () {
        throw TimeoutException('Server nicht erreichbar - Zeitüberschreitung');
      },
    );
    
    final response = await http.Response.fromStream(streamedResponse);

    print('Upload response status: ${response.statusCode}');
    print('Upload response body: ${response.body}'); // Add this for debugging

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Song uploaded successfully');
      SnackService().showSuccess(
        'Song "${song.header.name}" erfolgreich hochgeladen',
      );
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      print('Upload failed: Unauthorized');
      SnackService().showError('Keine Berechtigung zum Hochladen');
      return false;
    } else {
      print('Upload failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      SnackService().showError('Upload fehlgeschlagen: ${response.statusCode}');
      return false;
    }
  } on TimeoutException catch (e) {
    print('Timeout error: $e');
    SnackService().showError('Server nicht erreichbar (Timeout)');
    return false;
  } on SocketException catch (e) {
    print('Socket error: $e');
    SnackService().showError('Netzwerkverbindung fehlgeschlagen');
    return false;
  } catch (e) {
    print('Error uploading song to server: $e');
    if (e is http.ClientException) {
      SnackService().showError('Netzwerkfehler beim Hochladen');
    } else {
      SnackService().showError('Fehler beim Hochladen: $e');
    }
    return false;
  }
}

/// Gets the list of available subfolders on the server (optional helper)
Future<List<String>?> getServerSubfolders({
  required String serverUrl,
}) async {
  final tokenManager = ApiTokenManager();
  
  try {
    String normalizedUrl = serverUrl;
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://$normalizedUrl';
    }
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    final listEndpoint = '$normalizedUrl/api/song_data/files';
    final String? authToken = await tokenManager.getToken('serverApiToken');
    
    Map<String, String> headers = {};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.get(
      Uri.parse(listEndpoint),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final files = jsonData['files'] as List;
      
      // Extract unique folder names
      final folders = <String>{};
      for (var file in files) {
        final path = file['path'] as String;
        if (path.contains('/')) {
          final folder = path.split('/').first;
          folders.add(folder);
        }
      }
      
      return folders.toList()..sort();
    }
    
    return null;
  } catch (e) {
    print('Error fetching subfolders: $e');
    return null;
  }
}