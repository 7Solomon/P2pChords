import 'dart:async';

import 'package:P2pChords/networking/Pages/client/_components.dart';
import 'package:P2pChords/networking/Pages/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/device.dart';
import 'package:P2pChords/customeWidgets/ButtonWidget.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage>
    with SingleTickerProviderStateMixin {
  // State variables
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

  /// Check required permissions for nearby connections
  Future<void> _checkPermissions() async {
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    await provider.checkPermissions();
    provider.updateDisplaySnack(_showSnackBar);
    _showSnackBar("Permissions checked");
  }

  /// Display a snackbar message
  void _showSnackBar(String message) {
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
  }

  /// Callback when a server is discovered
  void _onDiscovered(String id, String name, String serviceId) {
    setState(() {
      _endpointMap[id] = DeviceInfo(name, serviceId);
    });
  }

  /// Start searching for nearby servers
  Future<void> _startSearch() async {
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);

    setState(() {
      _isSearching = true;
      _searchComplete = false;
      _searchProgress = 0;
      _endpointMap.clear();
    });

    _searchAnimationController.repeat();

    _searchTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_searchProgress < 3 && mounted) {
        setState(() {
          _searchProgress++;
        });
      }
    });

    try {
      await provider.startDiscovery(_onDiscovered);
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

  /// Get the current searching status text
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

  @override
  Widget build(BuildContext context) {
    final songSyncProvider = Provider.of<NearbyMusicSyncProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Find Server'),
        centerTitle: true,
        elevation: 0,
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
                // Search card
                buildSearchCard(
                  context: context,
                  isSearching: _isSearching,
                  searchComplete: _searchComplete,
                  onSearch: _startSearch,
                  searchingText: _getSearchingText(),
                ),

                // Connected server status
                if (songSyncProvider.connectedDeviceIds.isNotEmpty)
                  buildConnectedServerCard(
                      context, songSyncProvider.connectedDeviceIds.first),

                // Available servers section
                const SizedBox(height: 16),
                Text(
                  'Available Servers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Server list
                buildServerList(
                  context: context,
                  endpoints: _endpointMap,
                  onRequestConnection: (id) =>
                      songSyncProvider.requestConnection(id),
                  searchComplete: _searchComplete,
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
