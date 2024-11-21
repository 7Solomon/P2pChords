import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:nearby_connections/nearby_connections.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

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
          ),
        );
      }
    });
  }

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
      if (_searchProgress < 3) {
        if (mounted) {
          setState(() {
            _searchProgress++;
          });
        }
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
          _showSnackBar("Kein Client verbunden");
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
        return 'Searching';
    }
  }

  Widget _buildSearchAnimation() {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: _searchAnimationController.value,
        backgroundColor: Colors.blue.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songSyncProvider = Provider.of<NearbyMusicSyncProvider>(context);
    final Set<String> connectedDeviceIds = songSyncProvider.connectedDeviceIds;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Server'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: _buildSearchAnimation(),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSearching ? null : _startServer,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSearching)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            Text(
                              _isSearching
                                  ? 'Starting...'
                                  : _searchComplete
                                      ? 'Restart Server'
                                      : 'Start Server',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isSearching)
                        AnimatedOpacity(
                          opacity: _isSearching ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                Text(
                                  _getSearchingText(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Connected Devices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: connectedDeviceIds.isNotEmpty
                      ? ListView.builder(
                          itemCount: connectedDeviceIds.length,
                          itemBuilder: (context, index) {
                            final deviceId =
                                connectedDeviceIds.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(
                                      Icons.devices,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  title: Text(
                                    'Device $deviceId',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Connected',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isSearching
                                    ? 'Waiting for devices to connect...'
                                    : _searchComplete
                                        ? 'No devices connected'
                                        : 'Start server to allow connections',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              ElevatedButton(
                  child: Text('Permissions Check'),
                  onPressed: () {
                    _permissionsChecked = false;
                    _checkPermissions();
                  })
            ],
          ),
        ),
      ),
    );
  }
}
