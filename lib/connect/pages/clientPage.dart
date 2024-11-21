import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/device.dart';
import 'package:nearby_connections/nearby_connections.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({Key? key}) : super(key: key);

  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage>
    with SingleTickerProviderStateMixin {
  final Map<String, DeviceInfo> _endpointMap = {};
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
    if (!_permissionsChecked) {
      _checkPermissions();
      _permissionsChecked = true;
    }
  }

  Future<void> _checkPermissions() async {
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    await provider.checkPermissions();
    provider.updateDisplaySnack(_showSnackBar);
    _showSnackBar("Permissions checked");
  }

  void _showSnackBar(String message) {
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
  }

  // Can be added, aber will ich gerade nicht machen
  _onDiscovered(String id, String name, String serviceId) {
    setState(() {
      _endpointMap[id] = DeviceInfo(name, serviceId);
    });
  }

  void _startSearch() async {
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
      await provider.startDiscovery(_onDiscovered);

      // Ensure the loading animation plays for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchComplete = true;
        });

        _searchAnimationController.stop();
        _searchTimer?.cancel();

        if (_endpointMap.isEmpty) {
          _showSnackBar("No servers found nearby");
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
        _showSnackBar("Error searching for servers: ${e.toString()}");
      }
    }
  }

  String _getSearchingText() {
    switch (_searchProgress % 4) {
      case 0:
        return 'Initializing search';
      case 1:
        return 'Scanning for nearby servers';
      case 2:
        return 'Checking available devices';
      case 3:
        return 'Finalizing search results';
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
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songSyncProvider = Provider.of<NearbyMusicSyncProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Find Server'),
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
                        onPressed: _isSearching ? null : _startSearch,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSearching)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 10),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            Text(
                              _isSearching
                                  ? 'Searching...'
                                  : _searchComplete
                                      ? 'Search Again'
                                      : 'Search for Servers',
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
              if (songSyncProvider.connectedDeviceIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Connected to',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  songSyncProvider.connectedDeviceIds.first,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Available Servers',
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
                  child: _endpointMap.isNotEmpty
                      ? ListView.builder(
                          itemCount: _endpointMap.length,
                          itemBuilder: (context, index) {
                            final id = _endpointMap.keys.elementAt(index);
                            final deviceInfo = _endpointMap[id]!;

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
                                      Icons.computer,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  title: Text(
                                    deviceInfo.endpointName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    deviceInfo.serviceId,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.link, size: 18),
                                    label: const Text('Connect'),
                                    onPressed: () =>
                                        songSyncProvider.requestConnection(id),
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
                                Icons.wifi_find,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchComplete
                                    ? 'No servers found'
                                    : 'Search for available servers',
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
