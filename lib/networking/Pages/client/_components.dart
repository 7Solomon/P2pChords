import 'package:P2pChords/customeWidgets/ButtonWidget.dart';
import 'package:P2pChords/device.dart';
import 'package:P2pChords/networking/Pages/components.dart';
import 'package:flutter/material.dart';

/// Build the search action card specifically for client
Widget buildSearchCard({
  required BuildContext context,
  required bool isSearching,
  required bool searchComplete,
  required VoidCallback onSearch,
  required String searchingText,
}) {
  return buildActionCard(
    context: context,
    isInProgress: isSearching,
    actionComplete: searchComplete,
    onAction: onSearch,
    actionText: 'Search for Servers',
    inProgressText: searchingText,
    completeActionText: 'Search Again',
    actionIcon: Icons.search,
  );
}

/// Build the connected server status card
Widget buildConnectedServerCard(BuildContext context, String deviceId) {
  return Padding(
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
                  Text(
                    'Connected to',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  Text(
                    deviceId,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Build a server list item
Widget buildServerListItem(BuildContext context, String id,
    DeviceInfo deviceInfo, Function(String) onRequestConnection) {
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
            Icons.computer,
            color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: AppButton(
          text: 'Connect',
          icon: Icons.link,
          onPressed: () => onRequestConnection(id),
          type: AppButtonType.tertiary,
        ),
      ),
    ),
  );
}

/// Build the server list specifically for client page
Widget buildServerList({
  required BuildContext context,
  required Map<String, DeviceInfo> endpoints,
  required Function(String) onRequestConnection,
  required bool searchComplete,
}) {
  return Expanded(
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: endpoints.isNotEmpty
          ? ListView.builder(
              key: const ValueKey('server-list'),
              itemCount: endpoints.length,
              itemBuilder: (context, index) {
                final id = endpoints.keys.elementAt(index);
                final deviceInfo = endpoints[id]!;
                return buildServerListItem(
                    context, id, deviceInfo, onRequestConnection);
              },
            )
          : buildEmptyStatePlaceholder(
              context: context,
              icon: Icons.wifi_find,
              message: searchComplete
                  ? 'No servers found'
                  : 'Search for available servers',
              submessage: searchComplete
                  ? 'Try again or check if any servers are active'
                  : null,
            ),
    ),
  );
}
