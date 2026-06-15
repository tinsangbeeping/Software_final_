import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {

  final int index;

  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(

      currentIndex: index,

      onTap: onTap,

      selectedItemColor:
          const Color(0xFF00BFA6),

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "Analytics",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: "AI Assistant",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}