import 'dart:async';

import 'package:P2pChords/networking/Pages/server/functions.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/styling/Button.dart';
import 'package:P2pChords/networking/Pages/components.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage>
    with SingleTickerProviderStateMixin {
  // State variables
  bool _isStarting = false;
  bool _permissionsChecked = false;

  // Animation variables
  int _animationProgress = 0;
  late AnimationController _animationController;
  Timer? _animationTimer;
  bool _isModeSelectorExpanded = false;

  // Connection variables
  ConnectionMode? _selectedMode;
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
    //provider.setUserState(UserState.server);
    await _checkPermissions();
    _selectedMode = provider.connectionMode;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  /// Check required permissions
  Future<void> _checkPermissions() async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);
    bool status = await provider.checkPermissions();
    _showSnackBar(
        status ? "Berechtigungen erteilt" : "Berechtigungen nicht erteilt");
    if (!status) return;
    setState(() {
      _permissionsChecked = true;
    });
  }

  /// Show a snackbar message
  void _showSnackBar(String message) {
    if (!mounted) return;
    SnackService().showInfo(message);
  }

  /// Start the server based on selected connection mode
  Future<void> _startServer() async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);

    // Maybe good
    provider.setUserState(UserState.server);

    // Update connection mode in provider
    provider.setConnectionMode(_selectedMode!);

    // Start animation
    setState(() {
      _isStarting = true;
      _animationProgress = 0;
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

      // Start appropriate services based on mode
      if (_selectedMode == ConnectionMode.nearby ||
          _selectedMode == ConnectionMode.hybrid) {
        success = await provider.nearbyService.startServer();
      }

      if (_selectedMode == ConnectionMode.webSocket ||
          _selectedMode == ConnectionMode.hybrid) {
        success = await provider.webSocketService.startServer();
      }

      // Ensure the loading animation plays for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isStarting = false;
          provider.setServerRunning(success);
        });

        _animationController.stop();
        _animationTimer?.cancel();

        if (!success) {
          _showSnackBar("Server konnte nicht gestartet werden");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          provider.setServerRunning(false);
        });
        _animationController.stop();
        _animationTimer?.cancel();
        _showSnackBar("Fehler beim Starten des Servers: ${e.toString()}");
      }
    }
  }

  /// Stop the server
  Future<void> _stopServer() async {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);

    try {
      if (_selectedMode == ConnectionMode.nearby ||
          _selectedMode == ConnectionMode.hybrid) {
        await provider.nearbyService.stopServer();
      }

      if (_selectedMode == ConnectionMode.webSocket ||
          _selectedMode == ConnectionMode.hybrid) {
        await provider.webSocketService.stopServer();
      }

      setState(() {
        provider.setServerRunning(false);
      });

      _showSnackBar("Server gestoppt");
    } catch (e) {
      _showSnackBar("Fehler beim Stoppen des Servers: ${e.toString()}");
    }
  }

  /// Get status text based on current state
  String _getStatusText(bool isServerRunning) {
    if (_isStarting) {
      switch (_animationProgress % 4) {
        case 0:
          return 'Starte Server...';
        case 1:
          return 'Mache Server entdeckbar...';
        case 2:
          return 'Initialisiere Verbindungen...';
        case 3:
          return 'Bereit für Verbindungen...';
        default:
          return 'Starte Server...';
      }
    } else if (isServerRunning) {
      return 'Server läuft (${_getModeName(_selectedMode!)})';
    } else {
      return 'Server ist nicht aktiv';
    }
  }

  /// Get German name for connection mode
  String _getModeName(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.nearby:
        return 'Nearby';
      case ConnectionMode.webSocket:
        return 'WLAN';
      case ConnectionMode.hybrid:
        return 'Hybrid';
      default:
        return 'Unbekannt';
    }
  }

  /// Build the connected clients list
  Widget _buildConnectedClientsList(Set<String> connectedDeviceIds) {
    final provider = Provider.of<ConnectionProvider>(context, listen: false);
    final isServerRunning = provider.isServerRunning;

    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: connectedDeviceIds.isNotEmpty
            ? listViewClientList(connectedDeviceIds)
            : buildEmptyState(
                context: context,
                icon: Icons.devices_other,
                message: _isStarting
                    ? 'Warte auf Client-Verbindungen...'
                    : isServerRunning
                        ? 'Keine Clients verbunden'
                        : 'Starte den Server, um Verbindungen zu ermöglichen',
                submessage: isServerRunning && !_isStarting
                    ? 'Clients müssen nach diesem Server suchen, um zu verbinden'
                    : null,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
        });
  }

  Widget _buildMainContent() {
    final provider = Provider.of<ConnectionProvider>(context);
    final theme = Theme.of(context);
    final connectedDeviceIds = provider.connectedDeviceIds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Status chip
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: Text(
                provider.isServerRunning ? 'Aktiv' : 'Inaktiv',
                style: TextStyle(
                  color:
                      provider.isServerRunning ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor:
                  provider.isServerRunning ? Colors.green : Colors.grey,
            ),
          ),
        ],
        bottom: _isStarting
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
                if (!provider.isServerRunning)
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
                    isDisabled: provider.isServerRunning,
                    isExpanded: _isModeSelectorExpanded,
                    onExpandChanged: (expanded) {
                      setState(() {
                        _isModeSelectorExpanded = expanded;
                      });
                    },
                  ),

                const SizedBox(height: 16),

                // Server control card
                buildConnectionCard(
                  context: context,
                  isConnecting: _isStarting,
                  isConnected: provider.isServerRunning,
                  statusText: _getStatusText(provider.isServerRunning),
                  onAction:
                      provider.isServerRunning ? _stopServer : _startServer,
                  actionText: 'Server starten',
                  connectedText: 'Server stoppen',
                ),

                // Server IP address display
                if (provider.isServerRunning &&
                    (provider.connectionMode == ConnectionMode.webSocket ||
                        provider.connectionMode == ConnectionMode.hybrid)) ...[
                  FutureBuilder<String?>(
                    future: provider.webSocketService.getServerAddress(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                            'Error getting server address: ${snapshot.error}');
                      } else {
                        // print('snapshot.data: ${snapshot.data}'); // Already present
                        return serverIpDisplay(snapshot.data, context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  qrScannerButtonForServer(
                    context: context,
                    onScanComplete: (scannedToken) {
                      provider.webSocketService
                          .announceServerToClient(scannedToken);
                      SnackService().showInfo(
                          'Ankündigung an Client gesendet: $scannedToken');
                    },
                  ),
                ],
                // Connected clients section
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verbundene Clients',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (connectedDeviceIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${connectedDeviceIds.length}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Clients list
                _buildConnectedClientsList(connectedDeviceIds),

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
