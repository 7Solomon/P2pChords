import 'dart:async';

import 'package:P2pChords/networking/Pages/client/functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/device.dart';
import 'package:P2pChords/styling/Button.dart';
import 'package:P2pChords/networking/Pages/components.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:uuid/uuid.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({Key? key}) : super(key: key);

  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage>
    with SingleTickerProviderStateMixin {
  // State variables
  final Map<String, DeviceInfo> _discoveredServers = {};
  //bool _isSearching = false;
  bool _permissionsChecked = false;
  bool _isConnecting = false;
  bool _searchComplete = false;
  //String? _connectingServerId;
  //String? _connectedServerId;
  bool _isModeSelectorExpanded = false;
  String? _myClientTokenForQR;
  bool _isDisplayingQRForServer = false;

  // Animation variables
  int _animationProgress = 0;
  late AnimationController _animationController;
  Timer? _animationTimer;

  // Connection variables
  ConnectionMode? _selectedMode;

  //
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        setState(() {});
      });
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);
    _permissionsChecked = await _checkPermissions();
    _selectedMode = provider.connectionMode;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  /// Check required permissions
  Future<bool> _checkPermissions() async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);
    setState(() {
      _permissionsChecked = true;
    });
    return await provider.checkPermissions();
  }

  /// Show a snackbar message
  void _showSnackBar(String message) {
    if (!mounted) return;
    SnackService().showInfo(message);
  }

  /// Start searching for available servers
  Future<void> _startSearch() async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);

    provider.setUserState(UserState.client);

    // Update connection mode
    provider.setConnectionMode(_selectedMode!);

    // Start animation and reset state
    setState(() {
      provider.setDiscovering(true);
      _searchComplete = false;
      _animationProgress = 0;
      _discoveredServers.clear();
    });

    _animationController.repeat();
    _animationTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_animationProgress < 3 && mounted) {
        setState(() {
          _animationProgress++;
        });
      }
    });

    try {
      bool success = false;

      // Handle different connection modes
      if (_selectedMode == ConnectionMode.nearby ||
          _selectedMode == ConnectionMode.hybrid) {
        // Start nearby discovery
        success = await provider.nearbyService.startClient();

        // Register discovered servers
        for (var id in provider.visibleDevices) {
          _onServerDiscovered(id, "Nearby Server", "nearby");
        }
      }

      if (_selectedMode == ConnectionMode.webSocket ||
          _selectedMode == ConnectionMode.hybrid) {
        // Attempt network discovery

        final discoveredAddresses =
            await provider.webSocketService.startDiscovery();
        for (final address in discoveredAddresses) {
          _onServerDiscovered(address, "WLAN Server", "websocket");
        }
        success = discoveredAddresses.isNotEmpty || success;
      }

      // Ensure the animation plays for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          provider.setDiscovering(false);
          _searchComplete = true;
        });

        _animationController.stop();
        _animationTimer?.cancel();

        if (_discoveredServers.isEmpty) {
          _showSnackBar("Keine Server gefunden");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          provider.setDiscovering(false);
          _searchComplete = false;
        });
        _animationController.stop();
        _animationTimer?.cancel();
        _showSnackBar("Fehler bei der Serversuche: ${e.toString()}");
      }
    }
  }

  /// Record when a server is discovered
  void _onServerDiscovered(String id, String name, String connectionType) {
    setState(() {
      _discoveredServers[id] = DeviceInfo(name, id, connectionType);
    });
  }

  /// Connect to a selected server
  Future<void> _connectToServer(String serverId) async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);
    final serverInfo = _discoveredServers[serverId];
    if (serverInfo == null) return;

    setState(() {
      _isConnecting = true;
      //provider.connectedDeviceIds = serverId;
    });

    try {
      bool success = false;

      if (serverInfo.connectionType == "nearby" ||
          serverInfo.connectionType == "hybrid") {
        success = await provider.nearbyService.connectToServer(serverId);
      } else if (serverInfo.connectionType == "websocket" ||
          serverInfo.connectionType == "hybrid") {
        // websocket
        success = await provider.webSocketService.connectToServer(serverId);
      }

      if (success) {
        //setState(() {
        //  _connectedServerId = serverId;
        //});
        _showSnackBar("Erfolgreich mit Server verbunden");
      } else {
        _showSnackBar("Verbindung zum Server fehlgeschlagen");
      }
    } catch (e) {
      _showSnackBar("Fehler beim Verbinden: ${e.toString()}");
    } finally {
      setState(() {
        _isConnecting = false;
        //_connectingServerId = null;
      });
    }
  }

  /// Disconnect from the server
  Future<void> _disconnectFromServer(serverId) async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);

    try {
      final serverInfo = _discoveredServers[serverId];
      bool success = false;

      if (serverInfo?.connectionType == "nearby") {
        success = await provider.nearbyService.disconnectFromEndpoint(serverId);
      } else {
        success =
            await provider.webSocketService.disconnectFromEndpoint(serverId);
      }

      if (success) {
        _showSnackBar("Vom Server getrennt");
      }
    } catch (e) {
      _showSnackBar("Fehler beim Trennen: ${e.toString()}");
    }
  }

  /// Get status text based on current state
  String _getStatusText(bool isSearching, Set<String> serverIds) {
    if (isSearching) {
      switch (_animationProgress % 4) {
        case 0:
          return 'Initialisiere Suche...';
        case 1:
          return 'Scanne nach Servern...';
        case 2:
          return 'Prüfe verfügbare Geräte...';
        case 3:
          return 'Finalisiere Suchergebnisse...';
        default:
          return 'Suche...';
      }
    } else if (serverIds.isNotEmpty) {
      return 'Verbunden mit ${serverIds.length} Servern';
      //final serverInfos = _discoveredServers[serverId];
      //return 'Verbunden mit ${serverInfo?.endpointName ?? "Server"}';
    } else if (_searchComplete) {
      return '${_discoveredServers.length} Server gefunden';
    } else {
      return 'Klicke zum Suchen nach Servern';
    }
  }

  /// Build the connected server card
  Widget _buildConnectedServerCard(String serverId) {
    final serverInfo = _discoveredServers[serverId];
    if (serverInfo == null) return const SizedBox();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    serverInfo.connectionType == 'websocket'
                        ? Icons.wifi
                        : Icons.bluetooth,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verbundener Server',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serverInfo.endpointName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Trennen',
              icon: Icons.link_off,
              onPressed: () {
                _disconnectFromServer(serverId);
              },
              type: AppButtonType.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the server list
  Widget _buildServerList(Set<String> connectedDeviceIds) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _discoveredServers.isNotEmpty
            ? ListView.builder(
                key: const ValueKey('server-list'),
                itemCount: _discoveredServers.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  final id = _discoveredServers.keys.elementAt(index);
                  final deviceInfo = _discoveredServers[id]!;

                  // Don't show connected server in the list
                  if (connectedDeviceIds.contains(id)) {
                    return const SizedBox.shrink();
                  }

                  return buildServerCard(
                    context: context,
                    serverId: id,
                    serverName: deviceInfo.endpointName,
                    connectionType: deviceInfo.connectionType ?? 'nearby',
                    onConnect: () => _connectToServer(id),
                    isConnecting:
                        _isConnecting && connectedDeviceIds.contains(id),
                  );
                },
              )
            : buildEmptyState(
                context: context,
                icon: Icons.wifi_find,
                message: _searchComplete
                    ? 'Keine Server gefunden'
                    : 'Suche nach verfügbaren Servern',
                submessage: _searchComplete
                    ? 'Versuche es erneut oder prüfe, ob Server aktiv sind'
                    : null,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Fehler: ${snapshot.error}'),
          );
        } else {
          return _buildMainContent();
        }
      },
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final provider = Provider.of<ConnectionProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server finden'),
        centerTitle: true,
        elevation: 0,
        bottom: provider.isDiscovering
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child:
                    buildLoadingIndicator(context, _animationController.value),
              )
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection mode selector
                if (provider.connectedDeviceIds.isEmpty)
                  buildConnectionModeSelector(
                    context: context,
                    selectedMode: _selectedMode!,
                    onModeChanged: (mode) {
                      if (mode != null) {
                        setState(() {
                          _selectedMode = mode;
                        });
                      }
                    },
                    isDisabled: provider.isDiscovering,
                    isExpanded: _isModeSelectorExpanded,
                    onExpandChanged: (expanded) {
                      setState(() {
                        _isModeSelectorExpanded = expanded;
                      });
                    },
                  ),

                const SizedBox(height: 16),

                // Search card
                if (provider.connectedDeviceIds.isEmpty)
                  buildConnectionCard(
                    context: context,
                    isConnecting: provider.isDiscovering,
                    isConnected: _searchComplete,
                    statusText: _getStatusText(
                        provider.isDiscovering, provider.connectedDeviceIds),
                    onAction: _startSearch,
                    actionText: 'Server suchen',
                    connectedText: 'Erneut suchen',
                  ),

                // Connected server status
                if (provider.connectedDeviceIds.isNotEmpty)
                  for (String serverId in provider.connectedDeviceIds)
                    _buildConnectedServerCard(serverId),

                // Available servers section
                //if (_discoveredServers.isNotEmpty &&
                //    provider.connectedDeviceIds.isEmpty)
                //  Padding(
                //    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                //    child: Text(
                //      'Verfügbare Server',
                //      style: theme.textTheme.titleLarge?.copyWith(
                //        fontWeight: FontWeight.bold,
                //      ),
                //    ),
                //  ),
                if (provider.connectionMode == ConnectionMode.webSocket) ...[
                  qrScannerButton(
                    context: context,
                    onScanComplete: (scannedData) async {
                      // This is for client scanning server's QR (old flow, can be kept or removed)
                      // For the new flow, the server scans the client's QR.
                      // Consider if this button's purpose needs to be clarified or if it's for a different use case.
                      // For now, assuming it's for a scenario where server shows QR.
                      bool isListening = await provider.webSocketService
                          .listenForServerAnnouncement(scannedData);
                      if (isListening) {
                        _showSnackBar(
                            'QR-Code erfolgreich gescannt. Warte auf Server...');
                      } else {
                        _showSnackBar(
                            'Fehler beim Starten des Listeners für QR-Code. Bitte erneut versuchen.');
                      }
                    },
                    buttonText: 'Server-QR scannen (alt)', // Clarified text
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('QR für Server anzeigen'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    onPressed: _isDisplayingQRForServer
                        ? null
                        : () async {
                            final token = const Uuid().v4();
                            setState(() {
                              _myClientTokenForQR = token;
                              _isDisplayingQRForServer = true;
                            });

                            bool listening = await provider.webSocketService
                                .listenForServerAnnouncement(token);
                            if (listening) {
                              if (!mounted) return;
                              showClientQrDialog(context, token, () {
                                // This onDismiss is called when the dialog is closed.
                                final bool stillWaitingForConnectionViaThisQR =
                                    _isDisplayingQRForServer;
                                setState(() {
                                  _isDisplayingQRForServer = false;
                                  _myClientTokenForQR = null;
                                });
                                // If the dialog was closed AND we were still in the "displaying QR" state
                                // (meaning connection didn't happen through this QR flow to clear the flag),
                                // then stop listening.
                                // The listenForServerAnnouncement itself stops on success/error/done.
                                // This handles user manually closing the dialog.
                                if (stillWaitingForConnectionViaThisQR &&
                                    !provider.connectedDeviceIds.isNotEmpty) {
                                  // Check if not already connected
                                  provider.webSocketService
                                      .stopListeningForServerAnnouncement();
                                  _showSnackBar(
                                      "QR-Scan vom Server abgebrochen.");
                                }
                              });
                            } else {
                              setState(() {
                                _isDisplayingQRForServer = false;
                                _myClientTokenForQR = null;
                              });
                              _showSnackBar(
                                  "Fehler beim Starten des QR-Listeners.");
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Server-Adresse manuell eingeben'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    onPressed: () {
                      showManualAddressDialog(context);
                    },
                  ),
                ],

                // Server list
                _buildServerList(provider.connectedDeviceIds),

                // Permission check button
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AppButton(
                    text: 'Berechtigungen prüfen',
                    icon: Icons.security,
                    type: AppButtonType.tertiary,
                    onPressed: _checkPermissions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
