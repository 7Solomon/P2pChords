import 'package:flutter/material.dart';

class CDissmissible extends Dismissible {
  CDissmissible({
    required super.key,
    required super.child,
    VoidCallback? onDismissed,
    super.background,
    super.secondaryBackground,
    super.confirmDismiss,
    super.direction,
  }) : super(
          onDismissed: (direction) {
            if (onDismissed != null) {
              onDismissed();
            }
          },
        );

// Factory for delete/action pattern
  factory CDissmissible.deleteAndAction({
    required Key key,
    required Widget child,
    required Future<bool?> Function() deleteConfirmation,
    Future<bool?> Function()? confirmDeleteDismiss,
    Future<bool?> Function()? confirmActionDismiss,
    IconData deleteIcon = Icons.delete,
    IconData actionIcon = Icons.download,
    Color? deleteColor,
    Color? actionColor,
    DismissDirection? direction,
    BuildContext? context,
  }) {
    // Use theme colors if context is provided, otherwise use fallbacks
    final Color effectiveDeleteColor = deleteColor ??
        (context != null ? Theme.of(context).colorScheme.error : Colors.red);
    final Color effectiveActionColor = actionColor ??
        (context != null ? Theme.of(context).colorScheme.primary : Colors.blue);

    DismissDirection effectiveDirection = DismissDirection.none;

    // Enable both directions if both callbacks exist
    if (confirmDeleteDismiss != null && confirmActionDismiss != null) {
      effectiveDirection = DismissDirection.horizontal;
    }
    // Otherwise, enable only the specific direction
    else if (confirmDeleteDismiss != null) {
      effectiveDirection = DismissDirection.startToEnd;
    } else if (confirmActionDismiss != null) {
      effectiveDirection = DismissDirection.endToStart;
    }

    // Override with explicit direction if provided
    if (direction != null) {
      effectiveDirection = direction;
    }
    return CDissmissible(
      key: key,
      direction: effectiveDirection,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          confirmActionDismiss?.call();
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          bool? deleteConfirmed = await deleteConfirmation();

          if (deleteConfirmed == true) {
            return confirmDeleteDismiss?.call();
          } else {
            return false;
          }
        }
      },
      background: Container(
        color: effectiveDeleteColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(deleteIcon, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: effectiveActionColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(actionIcon, color: Colors.white),
      ),
      child: child,
    );
  }

  static Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text('Bestätige das Löschen', style: theme.textTheme.titleLarge),
          content: Text(
              'Bist du sicher, dass du das Element löschen willst? Das kann nicht mehr rückgängig gemacht werden.',
              style: theme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text('Löschen',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}

class CListTile extends ListTile {
  CListTile({
    super.key,
    required String title,
    required BuildContext context,
    String? subtitle,
    IconData? icon,
    double? iconSize,
    IconData? trailingIcon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) : super(
          leading: icon != null
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(icon,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: iconSize ?? 24.0),
                )
              : null,
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: subtitle != null
              ? Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)
              : null,
          trailing: trailingIcon != null
              ? Icon(trailingIcon,
                  size: 16, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: onTap ?? () {}, // Default no-op callback
          onLongPress: onLongPress ?? () {},
        );
}
