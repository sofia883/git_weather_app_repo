import 'package:flutter/material.dart';

class CustomPopupMenuButton extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSelected;

  const CustomPopupMenuButton({
    Key? key,
    required this.isDarkMode,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : Colors.black),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'search',
          child: Text('Search for Location'),
        ),
        PopupMenuItem(
          value: 'profile',
          child: Text('Profile'),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Text('Settings'),
        ),
        PopupMenuItem(
          value: 'light_mode',
          child: Text('Light Mode'),
        ),
        PopupMenuItem(
          value: 'dark_mode',
          child: Text('Dark Mode'),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Text('Logout'),
        ),
      ],
    );
  }
  
}
