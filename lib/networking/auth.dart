import 'dart:convert';
import 'package:P2pChords/networking/services/notification_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiTokenManager {
  final _storage = const FlutterSecureStorage();
  static const tokenMap = {'serverApiToken': 'server_api_token'};

  Future<void> saveToken(String key, String token) async {
    final String? tokenKey = tokenMap[key];
    if (tokenKey == null) {
      NotificationService().showError('Invalid token key: $key');
      return;
    }
    await _storage.write(key: tokenKey, value: token);
    NotificationService().showSuccess('Token saved successfully.');
  }

  Future<String?> getToken(String key) async {
    final String? tokenKey = tokenMap[key];
    if (tokenKey == null) {
      NotificationService().showError('Invalid token key: $key');
      return null;
    }
    final token = await _storage.read(key: tokenKey);
    if (token == null) {
      NotificationService().showError('Token not found for key: $key');
      return null;
    }
    NotificationService().showSuccess('Token retrieved successfully.');
    return token;
  }

  Future<void> deleteToken(String key) async {
    final String? tokenKey = tokenMap[key];
    if (tokenKey == null) {
      NotificationService().showError('Invalid token key: $key');
      return;
    }
    await _storage.delete(key: tokenKey);
    NotificationService().showSuccess('Token deleted successfully.');
  }
}

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final _tokenManager = ApiTokenManager();
  final Map<String, TextEditingController> _tokenControllers = {};
  final Map<String, String?> _currentTokenDisplays = {};
  bool _isLoading = false;

  List<String> _tokenKeys = [];

  @override
  void initState() {
    super.initState();
    _tokenKeys = ApiTokenManager.tokenMap.keys.toList();
    // Initialize controllers and load tokens for each key
    for (var key in _tokenKeys) {
      _tokenControllers[key] = TextEditingController();
      _currentTokenDisplays[key] = 'Loading...'; // Initial display
    }
    _loadAllTokens();
  }

  Future<void> _loadAllTokens() async {
    setState(() {
      _isLoading = true;
    });
    for (var key in _tokenKeys) {
      final token = await _tokenManager.getToken(key);
      if (mounted) {
        setState(() {
          _tokenControllers[key]?.text = token ?? '';
          _currentTokenDisplays[key] =
              token?.isNotEmpty == true ? token : 'Not set';
        });
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToken(String key) async {
    final controller = _tokenControllers[key];
    if (controller == null) return;

    if (controller.text.isEmpty) {
      await _clearToken(key);
      return;
    }
    setState(() {
      _isLoading = true;
    });
    await _tokenManager.saveToken(key, controller.text);
    if (mounted) {
      setState(() {
        _currentTokenDisplays[key] = controller.text;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token for "$key" saved successfully!')),
      );
    }
  }

  Future<void> _clearToken(String key) async {
    setState(() {
      _isLoading = true;
    });
    await _tokenManager.deleteToken(key);
    _tokenControllers[key]?.clear();
    if (mounted) {
      setState(() {
        _currentTokenDisplays[key] = 'Not set';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token for "$key" cleared!')),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _tokenControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTokenEditor(String tokenKey) {
    final controller = _tokenControllers[tokenKey];
    final currentDisplay = _currentTokenDisplays[tokenKey];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$tokenKey', // Display the key name
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor)),
              child: _isLoading && currentDisplay == 'Loading...'
                  ? const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          )))
                  : SelectableText(
                      currentDisplay ?? 'nicht verfügbar',
                      style: TextStyle(
                        fontFamily: currentDisplay == 'nicht verfügbar' ||
                                currentDisplay == 'Loading...'
                            ? null
                            : 'monospace',
                        color: currentDisplay == 'nicht verfügbar' ||
                                currentDisplay == 'Loading...'
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Gib einen eien Token für $tokenKey',
                hintText: 'hier token einfügen',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: _isLoading ? null : () => _clearToken(tokenKey),
                  child: const Text('Löschen'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: const Text('Speichern'),
                  onPressed: _isLoading ? null : () => _saveToken(tokenKey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Token Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white))),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Adjusted padding
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _tokenKeys.length,
                itemBuilder: (context, index) {
                  final key = _tokenKeys[index];
                  return _buildTokenEditor(key);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Note: ist eigentlich sicher gespeichert, aber toi toi toi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
