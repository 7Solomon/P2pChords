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

class CExpandableListTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final double? iconSize;
  final VoidCallback? onTap;
  final List<CExpandableAction> actions;
  final String uniqueKey;

  const CExpandableListTile({
    Key? key,
    required this.title,
    required this.uniqueKey,
    this.subtitle,
    this.icon,
    this.iconSize,
    this.onTap,
    this.actions = const [],
  }) : super(key: key);

  @override
  State<CExpandableListTile> createState() => _CExpandableListTileState();
}

class _CExpandableListTileState extends State<CExpandableListTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: _isExpanded
          ? BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      margin: _isExpanded
          ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8)
          : EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isExpanded ? 12 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isExpanded) {
                    _toggleExpanded();
                  } else {
                    widget.onTap?.call();
                  }
                },
                onLongPress: _toggleExpanded,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Leading icon or drag handle
                      if (_isExpanded)
                        Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.primary,
                          size: 28,
                        )
                      else if (widget.icon != null)
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            widget.icon,
                            color: theme.colorScheme.onPrimary,
                            size: widget.iconSize ?? 24.0,
                          ),
                        ),
                      const SizedBox(width: 16),
                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium,
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),                      
                    ],
                  ),
                ),
              ),
            ),
            // Expandable action buttons
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.actions
                      .map((action) => _buildActionButton(context, action))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, CExpandableAction action) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: IconButton.filled(
          onPressed: action.onPressed,
          icon: Icon(action.icon),
          style: IconButton.styleFrom(
            backgroundColor: action.backgroundColor ?? theme.colorScheme.primary,
            foregroundColor:
                action.foregroundColor ?? theme.colorScheme.onPrimary,
            minimumSize: const Size(48, 48),
          ),
          tooltip: action.tooltip,
        ),
      ),
    );
  }
}

class CExpandableAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CExpandableAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}
