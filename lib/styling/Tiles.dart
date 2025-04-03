import 'dart:ffi';

import 'package:flutter/material.dart';

class CDissmissible extends Dismissible {
  CDissmissible({
    required super.key,
    required super.child,
    VoidCallback? onDismissed,
    Widget? background,
    Widget? secondaryBackground,
    Future<bool?> Function(DismissDirection)? confirmDismiss,
    super.direction,
  }) : super(
          onDismissed: (direction) {
            if (onDismissed != null) {
              onDismissed();
            }
          },
          background: background,
          secondaryBackground: secondaryBackground,
          confirmDismiss: confirmDismiss,
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
    Color deleteColor = Colors.red,
    Color actionColor = Colors.blue,
    DismissDirection? direction,
  }) {
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
            return confirmDeleteDismiss
                ?.call(); // Remove the item from the list
          } else {
            return false;
          }
        }
      },
      background: Container(
        color: deleteColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(deleteIcon, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: actionColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(actionIcon, color: Colors.white),
      ),
      child: child,
    );
  }

  static Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bestätige das Löschen'),
          content: const Text(
              'Bist du sicher, dass du das Element löschen willst? Das kann nicht mehr rückgängig gemacht werden.'),
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
              child: const Text('Löschen'),
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
    String title = '',
    String? subtitle,
    IconData? icon,
    double? iconSize,
    Icons? arrowIcon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) : super(
          leading: icon != null
              ? CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child:
                      Icon(icon, color: Colors.white, size: iconSize ?? 24.0),
                )
              : null,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
              : null,
          trailing: arrowIcon != null
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null,
          onTap: onTap ?? () {}, // Default no-op callback
          onLongPress: onLongPress ?? () {},
        );
}
