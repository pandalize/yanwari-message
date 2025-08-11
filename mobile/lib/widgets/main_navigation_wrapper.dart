import 'package:flutter/material.dart';
import '../screens/recipient_select_screen.dart';
import '../screens/home_screen_redesigned.dart';
import '../screens/inbox_only_screen.dart';
import '../screens/schedule_only_screen.dart';
import '../screens/friend_management_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    // ホーム画面 - HomeScreenRedesigned
    const HomeScreenRedesigned(),
    // 送信画面 - RecipientSelectScreen
    const RecipientSelectScreen(),
    // 受信画面 - InboxOnlyScreen（受信トレイのみ）
    const InboxOnlyScreen(),
    // 予定画面 - ScheduleOnlyScreen（送信予定と送信済み）
    const ScheduleOnlyScreen(),
    // 友達画面 - FriendManagementScreen
    const FriendManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF92C9FF),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: '送信',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: '受信',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: '予定',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '友達',
          ),
        ],
      ),
    );
  }
}