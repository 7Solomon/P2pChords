import 'package:P2pChords/dataManagment/corrupted_storage.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/networking/auth.dart';

Future<String?> showServerSelectionDialog(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => const ServerSelectionDialog(),
  );
}

class ServerSelectionDialog extends StatefulWidget {
  const ServerSelectionDialog({super.key});

  @override
  State<ServerSelectionDialog> createState() => _ServerSelectionDialogState();
}

class _ServerSelectionDialogState extends State<ServerSelectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _tokenManager = ApiTokenManager();

  List<String> _savedIps = [];
  String? _selectedIp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIps();
  }

  Future<void> _loadIps() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      _savedIps = await _tokenManager.getSavedServerIps();
    } on StorageCorruptedException catch (e) {
      debugPrint('Storage corrupted: $e');
      _savedIps = [];
      
      if (mounted) {
        setState(() => _isLoading = false);
        
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
            content: const Text(
              'Der verschlüsselte Speicher ist beschädigt. Möchten Sie zur Debug-Seite gehen, um das Problem zu beheben?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

        if (shouldNavigate == true && mounted) {
          // Pop this dialog first
          Navigator.of(context).pop();
          
          // Navigate to debug page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StorageDebugPage(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading saved IPs: $e');
      _savedIps = [];
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Laden. Speicher wird zurückgesetzt.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final finalUrl = _ipController.text.trim();
    if (finalUrl.isEmpty) return;

    if (!_savedIps.contains(finalUrl)) {
      final saveConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.save, color: Colors.blue),
              SizedBox(width: 12),
              Text('Server speichern?'),
            ],
          ),
          content: Text(
            'Möchtest du "$finalUrl" für die zukünftige Verwendung speichern?',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nein'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ja, speichern'),
            ),
          ],
        ),
      );

      if (saveConfirmed == true) {
        await _tokenManager.addServerIp(finalUrl);
      }
    }

    if (mounted) {
      Navigator.of(context).pop(finalUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dns,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Server verbinden',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saved servers dropdown
                    if (_savedIps.isNotEmpty) ...[
                      const Text(
                        'Gespeicherte Server',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedIp,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(Icons.history),
                          ),
                          hint: const Text('Wähle einen Server'),
                          items: _savedIps.map((ip) {
                            return DropdownMenuItem(
                              value: ip,
                              child: Text(
                                ip,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedIp = value;
                              if (value != null) {
                                _ipController.text = value;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ODER',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Manual input
                    const Text(
                      'Neue Serveradresse',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        hintText: 'http://192.168.1.100:5000',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        if (_selectedIp != null && value != _selectedIp) {
                          setState(() => _selectedIp = null);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte eine Adresse eingeben';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Connect button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _connect,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_sync),
                            SizedBox(width: 12),
                            Text(
                              'Verbinden',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}