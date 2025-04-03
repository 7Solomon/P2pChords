import 'package:flutter/material.dart';

/// Widget for the differences header in text-based comparison
Widget buildDifferencesHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      children: [
        Icon(Icons.compare_arrows, size: 18),
        SizedBox(width: 8),
        Text(
          'Gefundene Unterschiede',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    ),
  );
}

/// Widget for a single difference item in text-based comparison
Widget buildDifferenceItem(
    BuildContext context, String path, Map<String, dynamic> difference) {
  final bool hasValueComparison =
      difference.containsKey('obj1') && difference.containsKey('obj2');

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Path and difference type
          Text(
            path,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          // Difference type badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: getDifferenceTypeColor(difference['typ']),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              difference['typ'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Description
          Text(
            difference['beschreibung'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),

          // Value comparison if available
          if (hasValueComparison) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Das ist das vorhandene',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[100]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          difference['obj1'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Das wäre das Neue',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[100]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          difference['obj2'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

/// Get color based on difference type
Color getDifferenceTypeColor(String type) {
  switch (type) {
    case 'Wertunterschied':
      return Colors.amber[700]!;
    case 'Neuer Wert':
    case 'Neue Elemente':
    case 'Zusätzlicher Schlüssel':
      return Colors.green[700]!;
    case 'Fehlender Schlüssel':
    case 'Fehlende Elemente':
      return Colors.red[700]!;
    case 'Typunterschied':
      return Colors.purple[700]!;
    default:
      return Colors.grey[700]!;
  }
}
