import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {

  final IconData icon;
  final String title;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return ListTile(

      leading: Icon(
        icon,
        color: const Color(
          0xFF00BFA6,
        ),
      ),

      title: Text(
        title,
      ),

      trailing: const Icon(
        Icons.chevron_right,
      ),
    );
  }
}