import 'dart:convert';
import 'package:P2pChords/dataManagment/corrupted_storage.dart';
import 'package:P2pChords/networking/services/notification_service.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ApiTokenManager {
  final _storage = const FlutterSecureStorage();
  static const tokenMap = {
    'serverApiToken': 'server_api_token',
  };
  static const _serverIpListKey = 'server_ip_list';

  // --- Static Accessor for single tokens ---
  static Future<String?> getStoredValue(String key) async {
    final String? tokenKey = tokenMap[key];
    if (tokenKey == null) return null;
    return await const FlutterSecureStorage().read(key: tokenKey);
  }

  // --- Methods for managing the list of Server IPs ---

  /// Fetches the saved list of server IPs.
  Future<List<String>> getSavedServerIps() async {
    try {
      final rawList = await _storage.read(key: _serverIpListKey);
      if (rawList == null) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(rawList);
      return decoded.cast<String>();
    } catch (e) {
      // Handle corrupted data - clear and throw custom exception
      debugPrint('Error reading server IPs (corrupted storage): $e');
      if (e.toString().contains('padding') || e.toString().contains('decrypt')) {
        throw StorageCorruptedException('Server IPs corrupted: $e');
      }
      return [];
    }
  }

  /// Saves a list of server IPs.
  Future<void> saveServerIps(List<String> ips) async {
    final rawList = jsonEncode(ips);
    await _storage.write(key: _serverIpListKey, value: rawList);
  }

  /// Adds a new IP to the saved list if it doesn't already exist.
  Future<void> addServerIp(String newIp) async {
    final currentIps = await getSavedServerIps();
    if (newIp.trim().isEmpty || currentIps.contains(newIp.trim())) return;
    currentIps.add(newIp.trim());
    await saveServerIps(currentIps);
  }

  /// Removes a specific IP from the saved list.
  Future<void> removeServerIp(String ipToRemove) async {
    final currentIps = await getSavedServerIps();
    currentIps.remove(ipToRemove);
    await saveServerIps(currentIps);
  }

  // --- Generic Token Methods ---

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
    try {
      final String? tokenKey = tokenMap[key];
      if (tokenKey == null) {
        return null;
      }
      return await _storage.read(key: tokenKey);
    } catch (e) {
      debugPrint('Error reading token $key (corrupted storage): $e');
      if (e.toString().contains('padding') || e.toString().contains('decrypt')) {
        throw StorageCorruptedException('Token $key corrupted: $e');
      }
      return null;
    }
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

  /// Clear all stored data
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }
}

/// Custom exception for corrupted storage
class StorageCorruptedException implements Exception {
  final String message;
  StorageCorruptedException(this.message);
  
  @override
  String toString() => message;
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
  List<String> _savedIps = [];
  final _newIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tokenKeys = ApiTokenManager.tokenMap.keys.toList();
    // Initialize controllers for tokens
    for (var key in _tokenKeys) {
      _tokenControllers[key] = TextEditingController();
      _currentTokenDisplays[key] = 'Loading...';
    }
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load tokens
      for (var key in _tokenKeys) {
        try {
          final token = await _tokenManager.getToken(key);
          if (mounted) {
            setState(() {
              _currentTokenDisplays[key] =
                  (token?.isNotEmpty ?? false) ? token : 'Nicht festgelegt';
            });
          }
        } catch (e) {
          if (e is StorageCorruptedException) {
            rethrow; // Pass it up to be handled below
          }
          debugPrint('Error loading token $key: $e');
          if (mounted) {
            setState(() {
              _currentTokenDisplays[key] = 'Fehler beim Laden';
            });
          }
        }
      }

      // Load IPs
      try {
        _savedIps = await _tokenManager.getSavedServerIps();
      } catch (e) {
        if (e is StorageCorruptedException) {
          rethrow; // Pass it up to be handled below
        }
        debugPrint('Error loading IPs: $e');
        _savedIps = [];
      }
    } on StorageCorruptedException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show dialog and navigate to debug page
        final shouldNavigate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 12),
                Text('Speicher beschädigt'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Der verschlüsselte Speicher ist beschädigt. Dies kann nach OS-Updates oder App-Neuinstallationen passieren.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Fehlerdetails: $e',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug-Seite öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

        if (shouldNavigate == true && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StorageDebugPage(),
            ),
          ).then((_) {
            // Reload after returning from debug page
            _loadAllData();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Daten: $e'),
            action: SnackBarAction(
              label: 'Debug',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StorageDebugPage(),
                  ),
                ).then((_) => _loadAllData());
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveToken(String key) async {
    final controller = _tokenControllers[key];
    if (controller == null) return;

    if (controller.text.isEmpty) {
      await _clearToken(key);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _tokenManager.saveToken(key, controller.text);
      if (mounted) {
        setState(() {
          _currentTokenDisplays[key] = controller.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wert für "$key" erfolgreich gespeichert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearToken(String key) async {
    setState(() => _isLoading = true);
    
    try {
      await _tokenManager.deleteToken(key);
      _tokenControllers[key]?.clear();
      if (mounted) {
        setState(() {
          _currentTokenDisplays[key] = 'Not set';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wert für "$key" gelöscht!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNewIp() async {
    if (_newIpController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _tokenManager.addServerIp(_newIpController.text);
      _newIpController.clear();
      await _loadAllData(); // Reload to show the new IP
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hinzufügen: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
    // Note: _loadAllData() will set _isLoading = false
  }

  Future<void> _removeIp(String ip) async {
    setState(() => _isLoading = true);
    
    try {
      await _tokenManager.removeServerIp(ip);
      await _loadAllData(); // Reload to reflect the deletion
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Entfernen: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
    // Note: _loadAllData() will set _isLoading = false
  }

  Future<void> _showExportDialog() async {
    final Map<String, bool> selectedItems = {
      for (var key in _tokenKeys) key: true,
      'serverIps': true, // Add server IPs to the export options
    };

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Daten exportieren'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Warnung: Der Export legt sensible Daten in einer unverschlüsselten JSON-Datei ab. Teilen Sie diese Datei nicht.',
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Wählen Sie die zu exportierenden Daten aus:'),
                    ...selectedItems.keys.map((key) {
                      return CheckboxListTile(
                        title: Text(key == 'serverIps' ? 'Server IPs' : key),
                        value: selectedItems[key],
                        onChanged: (bool? value) {
                          setDialogState(() {
                            selectedItems[key] = value ?? false;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _exportData(selectedItems);
                  },
                  child: const Text('Exportieren'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportData(Map<String, bool> selectedItems) async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> dataToExport =
          {}; // Changed to dynamic for list
      // Export tokens
      for (var key in _tokenKeys) {
        if (selectedItems[key] == true) {
          final value = await _tokenManager.getToken(key);
          if (value != null) {
            dataToExport[key] = value;
          }
        }
      }

      // Export server IPs
      if (selectedItems['serverIps'] == true) {
        final ips = await _tokenManager.getSavedServerIps();
        if (ips.isNotEmpty) {
          dataToExport[ApiTokenManager._serverIpListKey] = ips;
        }
      }

      if (dataToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Keine Daten zum Exportieren ausgewählt.')),
        );
        return;
      }

      final String jsonString = jsonEncode(dataToExport);
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Bitte Speicherort auswählen:',
        fileName: 'p2pchords_settings.json',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daten erfolgreich exportiert!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export fehlgeschlagen: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        int importCount = 0;
        // Import tokens
        for (var key in data.keys) {
          if (ApiTokenManager.tokenMap.containsKey(key)) {
            await _tokenManager.saveToken(key, data[key].toString());
            importCount++;
          }
        }

        // Import server IPs
        if (data.containsKey(ApiTokenManager._serverIpListKey)) {
          final List<dynamic> ips = data[ApiTokenManager._serverIpListKey];
          await _tokenManager.saveServerIps(ips.cast<String>());
          importCount++;
        }

        await _loadAllData(); // Refresh the UI with all imported values

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$importCount Werte erfolgreich importiert!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import fehlgeschlagen: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _tokenControllers.values) {
      controller.dispose();
    }
    _newIpController.dispose();
    super.dispose();
  }

  Widget _buildServerIpEditor() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gespeicherte Server IPs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_savedIps.isEmpty)
              const Text('Keine Server IPs gespeichert.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedIps.length,
                itemBuilder: (context, index) {
                  final ip = _savedIps[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ip),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeIp(ip),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newIpController,
                    decoration: const InputDecoration(
                      labelText: 'Neue Server IP hinzufügen',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _isLoading ? null : _addNewIp,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  tooltip: 'Hinzufügen',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenEditor(String tokenKey) {
    final controller = _tokenControllers[tokenKey];
    final currentDisplay = _currentTokenDisplays[tokenKey];
    final isSensitive = tokenKey.toLowerCase().contains('token');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              tokenKey, // Display the key name
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
                                currentDisplay == 'Loading...' ||
                                !isSensitive
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
                labelText: 'Neuen Wert für "$tokenKey" eingeben',
                hintText: 'Wert hier einfügen',
                border: const OutlineInputBorder(),
              ),
              obscureText: isSensitive,
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
        title: const Text('API Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: CSpeedDial(
        theme: Theme.of(context),
        children: [
          SpeedDialChild(
              child: const Icon(Icons.download),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              label: 'Exportiere Daten',
              onTap: () {
                _showExportDialog();
              }),
          SpeedDialChild(
              child: const Icon(Icons.upload),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              label: 'Importiere Daten',
              onTap: () {
                _importData();
              }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: [
                  _buildServerIpEditor(), // Add the IP editor to the list
                  ..._tokenKeys.map((key) => _buildTokenEditor(key)).toList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Note: Sensible Daten wie Tokens werden sicher im verschlüsselten Speicher des Geräts abgelegt.',
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
