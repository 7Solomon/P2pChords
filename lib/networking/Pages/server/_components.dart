import 'package:P2pChords/networking/Pages/components.dart';
import 'package:flutter/material.dart';

// MARK: - Server Page Components

/// Build the server start card specifically for server page
Widget buildServerCard({
  required BuildContext context,
  required bool isStarting,
  required bool serverRunning,
  required VoidCallback onStartServer,
  required String statusText,
}) {
  return buildActionCard(
    context: context,
    isInProgress: isStarting,
    actionComplete: serverRunning,
    onAction: onStartServer,
    actionText: 'Start Server',
    inProgressText: statusText,
    completeActionText: 'Restart Server',
    actionIcon: Icons.cast_connected,
  );
}

/// Build a connected client list item
Widget buildClientListItem(
  BuildContext context,
  String deviceId,
) {
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.phone_android,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          'Client $deviceId',
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
        trailing: Icon(
          Icons.check_circle_outline,
          color: Colors.green[700],
        ),
      ),
    ),
  );
}

/// Build the connected clients list specifically for server page
Widget buildConnectedClientsList({
  required BuildContext context,
  required Set<String> connectedDeviceIds,
  required bool isStarting,
  required bool serverRunning,
}) {
  return Expanded(
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: connectedDeviceIds.isNotEmpty
          ? ListView.builder(
              key: const ValueKey('clients-list'),
              itemCount: connectedDeviceIds.length,
              itemBuilder: (context, index) {
                final deviceId = connectedDeviceIds.elementAt(index);
                return buildClientListItem(context, deviceId);
              },
            )
          : buildEmptyStatePlaceholder(
              context: context,
              icon: Icons.devices_other,
              message: isStarting
                  ? 'Waiting for clients to connect...'
                  : serverRunning
                      ? 'No clients connected'
                      : 'Start server to allow connections',
              submessage: serverRunning && !isStarting
                  ? 'Clients need to search for this server to connect'
                  : null,
            ),
    ),
  );
}

/// Build server status chip for server page
Widget buildServerStatusChip(BuildContext context, bool isActive) {
  return buildStatusChip(
      context, isActive ? 'Active' : 'Inactive', Colors.green, isActive);
}
