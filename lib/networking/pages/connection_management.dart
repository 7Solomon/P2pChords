import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/networking/models/connection_models.dart';

class ConnectionManagementPage extends StatefulWidget {
  const ConnectionManagementPage({super.key});

  @override
  State<ConnectionManagementPage> createState() =>
      _ConnectionManagementPageState();
}

class _ConnectionManagementPageState extends State<ConnectionManagementPage> {
  final _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ConnectionProvider>();
    _deviceNameController.text = provider.deviceName;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        // Route to appropriate screen based on current state
        if (provider.isHub) {
          return _HubManagementScreen(provider: provider);
        } else if (provider.isSpoke && provider.isConnectedToHub) {
          return _SpokeConnectedScreen(provider: provider);
        } else if (provider.isSpoke && provider.isDiscovering) {
          return _SpokeDiscoveryScreen(provider: provider);
        } else {
          return _RoleSelectionScreen(
            provider: provider,
            deviceNameController: _deviceNameController,
          );
        }
      },
    );
  }
}

// ====================
// Role Selection Screen
// ====================
class _RoleSelectionScreen extends StatelessWidget {
  final ConnectionProvider provider;
  final TextEditingController deviceNameController;

  const _RoleSelectionScreen({
    required this.provider,
    required this.deviceNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verbindung'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Device Name Input
              TextField(
                controller: deviceNameController,
                decoration: InputDecoration(
                  labelText: 'Geräte-Name',
                  hintText: 'z.B. Johans iPad',
                  prefixIcon: const Icon(Icons.devices),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  provider.updateDeviceName(value);
                },
              ),

              const SizedBox(height: 32),

              // Hub Card
              _RoleCard(
                icon: Icons.router,
                title: 'Als Hub starten',
                subtitle: 'Server für andere Geräte',
                color: Colors.green,
                onTap: () async {
                  final success = await provider.startAsHub();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hub konnte nicht gestartet werden'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Spoke Card
              _RoleCard(
                icon: Icons.smartphone,
                title: 'Mit Hub verbinden',
                subtitle: 'Als Client verbinden',
                color: Colors.blue,
                onTap: () async {
                  await provider.startDiscovery();
                },
              ),

              const Spacer(),

              // Info text
              Text(
                'Wähle eine Rolle für dieses Gerät',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================
// Role Card Widget
// ====================
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================
// Hub Management Screen
// ====================
class _HubManagementScreen extends StatelessWidget {
  final ConnectionProvider provider;

  const _HubManagementScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub aktiv'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.router,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hub läuft',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: provider.getHubAddressAsync(),
                        builder: (context, snapshot) {
                          final address = snapshot.data ?? 'Laden...';
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                address,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                iconSize: 20,
                                onPressed: () {
                                  // TODO: Copy to clipboard
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Adresse kopiert'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      // TODO: QR Code here
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Connected Spokes
              Text(
                'Verbundene Geräte (${provider.connectedSpokeCount})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.connectedSpokes.isEmpty
                    ? Center(
                        child: Text(
                          'Keine Geräte verbunden',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.connectedSpokes.length,
                        itemBuilder: (context, index) {
                          final spoke = provider.connectedSpokes[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.smartphone),
                              title: Text(spoke.name),
                              subtitle: Text(
                                'Verbunden seit ${_formatDuration(DateTime.now().difference(spoke.connectedAt))}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed: () {
                                  // TODO: Kick spoke
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Stop Button
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hub beenden?'),
                      content: const Text(
                        'Alle verbundenen Geräte werden getrennt.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Beenden'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await provider.stopHub();
                  }
                },
                icon: const Icon(Icons.stop),
                label: const Text('Hub beenden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

// ====================
// Spoke Discovery Screen
// ====================
class _SpokeDiscoveryScreen extends StatelessWidget {
  final ConnectionProvider provider;

  const _SpokeDiscoveryScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubs suchen'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await provider.stopDiscovery();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Searching indicator
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Suche nach Hubs...'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Discovered Hubs
              Text(
                'Gefundene Hubs (${provider.discoveredHubs.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              Expanded(
                child: provider.discoveredHubs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keine Hubs gefunden',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.discoveredHubs.length,
                        itemBuilder: (context, index) {
                          final hub = provider.discoveredHubs[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.router,
                                color: hub.isValidated
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(hub.name),
                              subtitle: Text(hub.address),
                              trailing: hub.isValidated
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                              onTap: () async {
                                final success =
                                    await provider.connectToHub(hub);
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Verbindung fehlgeschlagen'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Manual add button
              OutlinedButton.icon(
                onPressed: () {
                  _showManualAddDialog(context, provider);
                },
                icon: const Icon(Icons.add),
                label: const Text('Manuell hinzufügen'),
              ),

              const SizedBox(height: 8),

              // Stop button
              ElevatedButton.icon(
                onPressed: () async {
                  await provider.stopDiscovery();
                },
                icon: const Icon(Icons.stop),
                label: const Text('Suche beenden'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualAddDialog(
      BuildContext context, ConnectionProvider provider) {
    final hostController = TextEditingController();
    final portController = TextEditingController(text: '8080');
    final nameController = TextEditingController(text: 'Manueller Hub');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hub manuell hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              decoration: const InputDecoration(
                labelText: 'IP-Adresse',
                hintText: '192.168.1.100',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '8080',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final host = hostController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 8080;
              final name = nameController.text.trim();

              if (host.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('IP-Adresse erforderlich')),
                );
                return;
              }

              Navigator.pop(context);

              final success = await provider.addManualHub(host, port, name);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Hub hinzugefügt'
                          : 'Hub konnte nicht validiert werden',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}

// ====================
// Spoke Connected Screen
// ====================
class _SpokeConnectedScreen extends StatelessWidget {
  final ConnectionProvider provider;

  const _SpokeConnectedScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verbunden'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verbunden mit Hub',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      // TODO: Show hub name and address
                      const Text(
                        'Hub-Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.signal_cellular_alt,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Verbindung gut',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Disconnect Button
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Verbindung trennen?'),
                      content: const Text(
                        'Die Verbindung zum Hub wird getrennt.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Trennen'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await provider.disconnectFromHub();
                  }
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Verbindung trennen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}