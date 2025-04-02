import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _connectionKeyName = 'connection_key';
  final storage = const FlutterSecureStorage();

  // Generate or retrieve connection key
  Future<String> getConnectionKey() async {
    String? existingKey = await storage.read(key: _connectionKeyName);

    if (existingKey == null) {
      // Generate new random key
      final key = _generateRandomKey();
      await storage.write(key: _connectionKeyName, value: key);
      return key;
    }

    return existingKey;
  }

  // Generate random key
  String _generateRandomKey() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Validate connection request
  bool validateConnectionRequest(
      Map<String, dynamic> request, String expectedKey) {
    if (!request.containsKey('authKey')) {
      return false;
    }

    return request['authKey'] == expectedKey;
  }

  // Create authenticated message
  Map<String, dynamic> createAuthenticatedMessage(
      Map<String, dynamic> message, String key) {
    final authenticatedMessage = Map<String, dynamic>.from(message);
    authenticatedMessage['authKey'] = key;

    // Add timestamp to prevent replay attacks
    authenticatedMessage['timestamp'] = DateTime.now().millisecondsSinceEpoch;

    return authenticatedMessage;
  }
}
