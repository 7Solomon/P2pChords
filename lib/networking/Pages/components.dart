import 'package:P2pChords/customeWidgets/ButtonWidget.dart';
import 'package:flutter/material.dart';

/// Build a linear progress animation (used by both client and server)
Widget buildSearchAnimation(BuildContext context, double value) {
  return SizedBox(
    height: 4,
    child: LinearProgressIndicator(
      value: value,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      valueColor:
          AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
    ),
  );
}

/// Display a standard snackbar message
void showSnackBar(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

/// Generic action card with progress indicator
Widget buildActionCard({
  required BuildContext context,
  required bool isInProgress,
  required bool actionComplete,
  required VoidCallback onAction,
  required String actionText,
  required String inProgressText,
  required String completeActionText,
  required IconData actionIcon,
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          AppButton(
            text: isInProgress
                ? inProgressText
                : actionComplete
                    ? completeActionText
                    : actionText,
            icon: isInProgress ? null : actionIcon,
            onPressed: () {
              isInProgress ? null : onAction();
            },
            type: AppButtonType.primary,
          ),
          if (isInProgress)
            AnimatedOpacity(
              opacity: isInProgress ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    Text(
                      inProgressText,
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
            ),
        ],
      ),
    ),
  );
}

/// Generic status badge for app bar
Widget buildStatusChip(
    BuildContext context, String label, Color color, bool isActive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? color : Colors.grey,
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: isActive ? color : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? color : Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

/// Generic empty state placeholder
Widget buildEmptyStatePlaceholder({
  required BuildContext context,
  required IconData icon,
  required String message,
  String? submessage,
}) {
  return Center(
    key: const ValueKey('empty-state'),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        if (submessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              submessage,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}
