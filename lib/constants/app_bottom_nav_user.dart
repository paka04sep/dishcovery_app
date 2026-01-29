import 'package:flutter/material.dart';
import '../screen/history_screen.dart';
import '../screen/swipescreen.dart';
import '../screen/user_profile_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.history,
              color: currentIndex == 0 ? Colors.orange : Colors.grey,
              size: currentIndex == 0 ? 40 : 30,
            ),
            onPressed: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.fork_right,
              size: currentIndex == 1 ? 40 : 30,
              color: currentIndex == 1 ? Colors.orange : Colors.grey,
            ),
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SwipScreen()),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: currentIndex == 2 ? Colors.orange : Colors.grey,
              size: currentIndex == 2 ? 40 : 30,
            ),
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
