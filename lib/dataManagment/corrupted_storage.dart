import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:P2pChords/networking/auth.dart';

class StorageDebugPage extends StatefulWidget {
  const StorageDebugPage({super.key});

  @override
  State<StorageDebugPage> createState() => _StorageDebugPageState();
}

class _StorageDebugPageState extends State<StorageDebugPage> {
  final _storage = const FlutterSecureStorage();
  Map<String, String?> _allData = {};
  Map<String, String> _errors = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scanStorage();
  }

  Future<void> _scanStorage() async {
    setState(() {
      _isLoading = true;
      _allData.clear();
      _errors.clear();
    });

    try {
      final allKeys = await _storage.readAll();
      
      for (var entry in allKeys.entries) {
        try {
          // Try to read each value
          final value = await _storage.read(key: entry.key);
          _allData[entry.key] = value;
        } catch (e) {
          _errors[entry.key] = e.toString();
          _allData[entry.key] = null;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Scannen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteKey(String key) async {
    try {
      await _storage.delete(key: key);
      await _scanStorage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$key gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warnung'),
        content: const Text('Alle gespeicherten Daten werden gelöscht!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Alles löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storage.deleteAll();
        await _scanStorage();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alle Daten gelöscht')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearCorrupted() async {
    if (_errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine beschädigten Daten gefunden')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beschädigte Daten löschen'),
        content: Text('${_errors.length} beschädigte Einträge werden gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      int deleted = 0;
      for (var key in _errors.keys) {
        try {
          await _storage.delete(key: key);
          deleted++;
        } catch (e) {
          debugPrint('Failed to delete $key: $e');
        }
      }
      await _scanStorage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$deleted beschädigte Einträge gelöscht')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanStorage,
            tooltip: 'Neu laden',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Card(
                  margin: const EdgeInsets.all(16),
                  color: _errors.isEmpty ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zusammenfassung',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Gesamt: ${_allData.length} Einträge'),
                        Text(
                          'Beschädigt: ${_errors.length} Einträge',
                          style: TextStyle(
                            color: _errors.isEmpty ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_errors.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _clearCorrupted,
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Beschädigte Daten löschen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Storage Entries List
                Expanded(
                  child: _allData.isEmpty
                      ? const Center(child: Text('Keine Daten im Speicher'))
                      : ListView.builder(
                          itemCount: _allData.length,
                          itemBuilder: (context, index) {
                            final key = _allData.keys.elementAt(index);
                            final value = _allData[key];
                            final hasError = _errors.containsKey(key);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              color: hasError ? Colors.red.shade50 : null,
                              child: ExpansionTile(
                                leading: Icon(
                                  hasError ? Icons.error : Icons.check_circle,
                                  color: hasError ? Colors.red : Colors.green,
                                ),
                                title: Text(
                                  key,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: hasError
                                    ? Text(
                                        'ERROR: ${_errors[key]}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        value?.substring(
                                              0,
                                              value.length > 50 ? 50 : value.length,
                                            ) ??
                                            'null',
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () => _deleteKey(key),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (hasError) ...[
                                          const Text(
                                            'Fehlerdetails:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          SelectableText(
                                            _errors[key]!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ] else ...[
                                          const Text(
                                            'Wert:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          SelectableText(
                                            value ?? 'null',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Bottom Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Alle Daten löschen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}