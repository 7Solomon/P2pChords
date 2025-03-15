import 'dart:async';

import 'package:P2pChords/networking/Pages/components.dart';
import 'package:P2pChords/networking/Pages/server/_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/customeWidgets/ButtonWidget.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _searchComplete = false;
  bool _permissionsChecked = false;
  int _searchProgress = 0;
  late AnimationController _searchAnimationController;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        setState(() {});
      });
    // Move permissions check to after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_permissionsChecked) {
        _checkPermissions();
        _permissionsChecked = true;
      }
    });
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// Check required permissions for nearby connections
  Future<void> _checkPermissions() async {
    if (!mounted) return;
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    provider.updateDisplaySnack(_showSnackBar);
    await provider.checkPermissions();
    if (mounted) {
      _showSnackBar("Permissions checked");
    }
  }

  /// Display a snackbar message
  void _showSnackBar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    });
  }

  /// Start the server advertising
  void _startServer() async {
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);

    setState(() {
      _isSearching = true;
      _searchComplete = false;
      _searchProgress = 0;
    });

    // Start the loading animation
    _searchAnimationController.repeat();

    // Create a periodic timer to update search progress
    _searchTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_searchProgress < 3 && mounted) {
        setState(() {
          _searchProgress++;
        });
      }
    });

    try {
      await provider.startAdvertising();

      // Ensure the loading animation plays for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchComplete = true;
        });

        _searchAnimationController.stop();
        _searchTimer?.cancel();

        if (provider.connectedDeviceIds.isEmpty) {
          _showSnackBar("No clients connected");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchComplete = true;
        });
        _searchAnimationController.stop();
        _searchTimer?.cancel();
        _showSnackBar("Error starting server: ${e.toString()}");
      }
    }
  }

  /// Get the current server status text based on progress
  String _getSearchingText() {
    switch (_searchProgress % 4) {
      case 0:
        return 'Starting server';
      case 1:
        return 'Making server discoverable';
      case 2:
        return 'Waiting for connections';
      case 3:
        return 'Ready for devices';
      default:
        return 'Starting server...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final songSyncProvider = Provider.of<NearbyMusicSyncProvider>(context);
    final theme = Theme.of(context);
    final connectedDeviceIds = songSyncProvider.connectedDeviceIds;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Server'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: buildServerStatusChip(context, _searchComplete),
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: buildSearchAnimation(
                    context, _searchAnimationController.value),
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
                // Server card
                buildServerCard(
                  context: context,
                  isStarting: _isSearching,
                  serverRunning: _searchComplete,
                  onStartServer: _startServer,
                  statusText: _getSearchingText(),
                ),

                // Connected clients section
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Connected Clients',
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
                buildConnectedClientsList(
                  context: context,
                  connectedDeviceIds: connectedDeviceIds,
                  isStarting: _isSearching,
                  serverRunning: _searchComplete,
                ),

                // Debug permission check button
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AppButton(
                    text: 'Check Permissions',
                    icon: Icons.security,
                    type: AppButtonType.tertiary,
                    onPressed: () {
                      _permissionsChecked = false;
                      _checkPermissions();
                    },
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
