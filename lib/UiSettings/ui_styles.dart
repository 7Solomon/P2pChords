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
  static const TextStyle valueStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 10.0,
    color: Colors.grey,
  );

  static BoxDecoration floatingPanelDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: const [
      BoxShadow(color: Colors.black26, blurRadius: 8.0, offset: Offset(0, 2)),
    ],
  );
}

class ControlsRow extends StatelessWidget {
  final String label;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String value;
  final String? minValue;
  final String? maxValue;

  const ControlsRow({
    Key? key,
    required this.label,
    required this.onDecrease,
    required this.onIncrease,
    required this.value,
    this.minValue,
    this.maxValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100, // Fixed width for labels
            child: Text(
              label,
              style: UiStyles.labelStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (minValue != null)
                  Text(minValue!, style: UiStyles.smallTextStyle),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: onDecrease,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: UiStyles.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              value,
                              style: UiStyles.valueStyle,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: onIncrease,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (maxValue != null)
                  Text(maxValue!, style: UiStyles.smallTextStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
