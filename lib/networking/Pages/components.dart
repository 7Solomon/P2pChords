import 'package:flutter/material.dart';
import 'package:P2pChords/styling/Button.dart';
import 'package:P2pChords/state.dart';

/// Builds a collapsible card for connection mode selection with radio buttons in German
Widget buildConnectionModeSelector({
  required BuildContext context,
  required ConnectionMode selectedMode,
  required Function(ConnectionMode?) onModeChanged,
  required bool isDisabled,
  bool isExpanded = false,
  Function(bool)? onExpandChanged,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse button
        InkWell(
          onTap: onExpandChanged != null
              ? () => onExpandChanged(!isExpanded)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Verbindungsmodus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Nearby Only option
                RadioListTile<ConnectionMode>(
                  title: const Text('Nur Nearby'),
                  subtitle: const Text('Verbindung zu Geräten in der Nähe'),
                  value: ConnectionMode.nearby,
                  groupValue: selectedMode,
                  onChanged: isDisabled ? null : onModeChanged,
                  dense: true,
                ),

                // WebSocket Only option
                RadioListTile<ConnectionMode>(
                  title: const Text('Nur WLAN'),
                  subtitle: const Text('Verbindung über WLAN-Netzwerk'),
                  value: ConnectionMode.webSocket,
                  groupValue: selectedMode,
                  onChanged: isDisabled ? null : onModeChanged,
                  dense: true,
                ),

                // Hybrid Option
                RadioListTile<ConnectionMode>(
                  title: const Text('Beides (Hybrid)'),
                  subtitle: const Text('Nutze Nearby und WLAN gleichzeitig'),
                  value: ConnectionMode.hybrid,
                  groupValue: selectedMode,
                  onChanged: isDisabled ? null : onModeChanged,
                  dense: true,
                ),
              ],
            ),
          ),

        // Show current selection when collapsed
        if (!isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Chip(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              label: Text(
                _getModeName(selectedMode),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Get the German name for the connection mode
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

/// Builds a card for showing connection status with action button
Widget buildConnectionCard({
  required BuildContext context,
  required bool isConnecting,
  required bool isConnected,
  required String statusText,
  required VoidCallback onAction,
  required String actionText,
  required String connectedText,
}) {
  final theme = Theme.of(context);

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? Icons.check_circle : Icons.power_settings_new,
                  color: isConnected ? Colors.green : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Connected' : 'Connection',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Button section
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: AppButton(
              text: isConnected ? connectedText : actionText,
              icon: isConnected ? Icons.refresh : Icons.send,
              onPressed: onAction,
              //isLoading: isConnecting,
              type:
                  isConnected ? AppButtonType.tertiary : AppButtonType.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds a progress loader with animation
Widget buildLoadingIndicator(BuildContext context, double value) {
  return Container(
    height: 4,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ],
      ),
    ),
    child: LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.transparent,
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
    ),
  );
}

/// Builds an empty state placeholder with an icon and message
Widget buildEmptyState({
  required BuildContext context,
  required IconData icon,
  required String message,
  String? submessage,
}) {
  final theme = Theme.of(context);

  return Center(
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              const SizedBox(height: 8),
              Text(
                submessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Builds a server card for the client page that can be tapped to connect
Widget buildServerCard({
  required BuildContext context,
  required String serverId,
  required String serverName,
  required String connectionType,
  required VoidCallback onConnect,
  required bool isConnecting,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: onConnect,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                connectionType == 'websocket' ? Icons.wifi : Icons.bluetooth,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connectionType == 'websocket'
                        ? 'WLAN-Verbindung'
                        : 'Bluetooth-Verbindung',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
          ],
        ),
      ),
    ),
  );
}
