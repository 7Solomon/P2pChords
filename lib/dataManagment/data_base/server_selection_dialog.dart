import 'package:flutter/material.dart';
import 'package:P2pChords/networking/auth.dart';

/// Shows a dialog to select a server and returns the chosen URL.
/// Returns `null` if the dialog is cancelled.
Future<String?> showServerSelectionDialog(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    // The builder now just calls the self-contained dialog
    builder: (context) => const ServerSelectionDialog(),
  );
}

class ServerSelectionDialog extends StatefulWidget {
  const ServerSelectionDialog({super.key});

  @override
  State<ServerSelectionDialog> createState() => _ServerSelectionDialogState();
}

class _ServerSelectionDialogState extends State<ServerSelectionDialog> {
  // 1. Create instances for the form, controller, and token manager
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _tokenManager = ApiTokenManager();

  // 2. State variables for the dialog
  List<String> _savedIps = [];
  String? _selectedIp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 3. Load the IPs when the dialog is first created
    _loadIps();
  }

  Future<void> _loadIps() async {
    setState(() => _isLoading = true);
    _savedIps = await _tokenManager.getSavedServerIps();
    setState(() => _isLoading = false);
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

    // If the final URL is not in the original saved list, ask to save it.
    if (!_savedIps.contains(finalUrl)) {
      final saveConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Server speichern?'),
          content: Text(
              'Soll die neue Adresse "$finalUrl" für die zukünftige Verwendung gespeichert werden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nein'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ja, speichern'),
            ),
          ],
        ),
      );

      if (saveConfirmed == true) {
        await _tokenManager.addServerIp(finalUrl);
      }
    }

    // Pop the dialog and return the selected URL
    if (mounted) {
      Navigator.of(context).pop(finalUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server auswählen'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_savedIps.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedIp,
                        hint: const Text('Gespeicherten Server wählen'),
                        items: _savedIps.map((ip) {
                          return DropdownMenuItem(value: ip, child: Text(ip));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIp = value;
                            if (value != null) {
                              _ipController.text = value;
                            }
                          });
                        },
                        decoration:
                            const InputDecoration(border: OutlineInputBorder()),
                      ),
                    if (_savedIps.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: Text('ODER')),
                      ),
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Server-Adresse eingeben oder bearbeiten',
                        hintText: 'http://192.168.1.100:8080',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (_selectedIp != null && value != _selectedIp) {
                          setState(() {
                            _selectedIp = null;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte eine Adresse auswählen oder eingeben.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _connect,
          child: const Text('Verbinden'),
        ),
      ],
    );
  }
}
