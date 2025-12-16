import 'package:flutter/material.dart';

import 'package:service_app/PPG%20Finger/ppg_assessment.dart';
import 'package:service_app/Prakriti_Chatbot/chat_screen.dart';



import 'package:service_app/model/Screens_home/acccount_screen.dart';
import 'package:service_app/model/Screens_home/explore_screen.dart';
import 'package:service_app/model/Screens_home/inbox.dart';
import 'package:service_app/model/Screens_home/post.dart';

import 'package:service_app/views/Host_Screens/Home_Screen.dart';
import 'package:service_app/views/Host_Screens/My_Treatment_Submission.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selelectedIndex = 0;
  bool _showUnreadBadge = true;

  final List<String> screenTitles = [
    'Home',
    'Saved',
    'Inbox',
    'Chat',
    'Profile',
    'Find Safest Travel Path',
    "new"
  ];

  final List<Widget> screens = [
    
   Booking(),
      MyPoastingScreen(),
    AccountScreen(),
  // This should be imported from your settings.dart file
  ];

  BottomNavigationBarItem customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(iconData, color: Colors.black),
      activeIcon: Icon(iconData, color: Colors.blue),
      label: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: IndexedStack(
        index: selelectedIndex,
        children: screens,
      ),
      floatingActionButton: selelectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _showUnreadBadge = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
              backgroundColor: Colors.blue[600],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 30),
                  if (_showUnreadBadge)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) {
          setState(() {
            selelectedIndex = i;
          });
        },
        currentIndex: selelectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          customNavigationBarItem(0, Icons.home, screenTitles[0]),
          customNavigationBarItem(1, Icons.save_rounded, screenTitles[1]),
          customNavigationBarItem(2, Icons.calendar_month, screenTitles[2]),
          customNavigationBarItem(3, Icons.message, screenTitles[3]),
          customNavigationBarItem(4, Icons.person, screenTitles[4]),
          customNavigationBarItem(5, Icons.map, screenTitles[5]),
          customNavigationBarItem(6, Icons.production_quantity_limits_outlined, screenTitles[6]),
        ],
      ),
    );
  }
}