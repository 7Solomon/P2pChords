import 'package:flutter/material.dart';

class UiStyles {
  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.blueGrey;
  static const Color backgroundColor = Colors.white;

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  // Padding
  static const EdgeInsets standardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);

  // Card decoration
  static BoxDecoration controlsCardDecoration = BoxDecoration(
    color: Colors.grey[100],
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16.0),
      topRight: Radius.circular(16.0),
    ),
    boxShadow: const [
      BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 4.0),
    ],
  );
}

class ControlsRow extends StatelessWidget {
  final String label;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String value;

  const ControlsRow({
    Key? key,
    required this.label,
    required this.onDecrease,
    required this.onIncrease,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: UiStyles.smallPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onDecrease,
            color: UiStyles.primaryColor,
          ),
          Flexible(
            child: Text(
              '$label: $value',
              style: UiStyles.labelStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onIncrease,
            color: UiStyles.primaryColor,
          ),
        ],
      ),
    );
  }
}
