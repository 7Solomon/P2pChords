import 'package:flutter/material.dart';

class CustomListTile extends ListTile {
  CustomListTile({
    Key? key,
    String title = '',
    String subtitle = '',
    IconData icon = Icons.info,
    bool arrowBool = true,
    bool iconBool = true,
    double iconSize = 24.0, // Size of the icon
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
        vertical: 8.0, horizontal: 16.0), // Default padding
    VoidCallback? onTap,
  }) : super(
          key: key,
          contentPadding: contentPadding, // Use the provided padding
          leading: iconBool
              ? CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(icon, color: Colors.white, size: iconSize),
                )
              : null,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          trailing:
              arrowBool ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
          onTap: onTap ?? () {}, // Default no-op callback
        );
}
