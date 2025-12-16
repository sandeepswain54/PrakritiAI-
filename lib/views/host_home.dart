import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:service_app/Frontend_Flutter/ayurhome.dart';

import 'package:service_app/PPG%20Finger/ppg_assessment.dart';
import 'package:service_app/TongueDiagnosis/TongueDiagnosis.dart';
import 'package:service_app/UI%20SCREEN/front_screen.dart';
import 'package:service_app/Voice_AI/AI_Voice.dart';
import 'package:service_app/Voice_AI/animated_dhanvantri_ai.dart';
import 'package:service_app/Voice_AI/assets_avatar_lipsync.dart' show AssetsAvatarLipSync;
import 'package:service_app/Voice_AI/real_talking_avatar.dart' show RealTalkingAvatar;
import 'package:service_app/Voice_AI/realistic_dhanvantri_avatar.dart';
import 'package:service_app/Voice_AI/ghar_ke_nuske_ai.dart';
import 'package:service_app/Voice_AI/voice_ai_chat.dart';
import 'package:service_app/model/Screens_home/acccount_screen.dart';
import 'package:service_app/model/Screens_home/explore_screen.dart';
import 'package:service_app/model/Screens_home/inbox.dart';
import 'package:service_app/model/Screens_home/post.dart';

import 'package:service_app/views/Host_Screens/Home_Screen.dart';

import 'package:service_app/views/onboarding_screen.dart';

class HostHomeScreen extends StatefulWidget {

  int? Index;

  HostHomeScreen({super.key, this.Index,});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  int _selectedIndex = 0;

  final List<String> _screenTitles = [
    'Home',
    'Post',
    'Booking',
    'Talk',
    'Tracking',
    'Profile',
  ];

  final List<Widget> _screens = [
     Booking(),
    const Post(),
    const GharKeNuskeAI(avatarImagePath: 'assets/demo.png'),
    PPGAssessmentScreen(),
    const AccountScreen(),
  ];

  BottomNavigationBarItem _customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        color: _selectedIndex == index ? Colors.blue : Colors.black,
      ),
      label: title,
    );
  }



@override
  void initState() {
    // TODO: implement initState
    super.initState();

    _selectedIndex = widget.Index ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        items: [
          _customNavigationBarItem(0, Icons.home, _screenTitles[0]),
          _customNavigationBarItem(1, Icons.post_add_outlined, _screenTitles[1]),
          _customNavigationBarItem(2, Icons.chat_bubble, _screenTitles[2]),
          _customNavigationBarItem(3, Icons.psychology, _screenTitles[3]),
          _customNavigationBarItem(4, Icons.gps_fixed, _screenTitles[4]),
          _customNavigationBarItem(5, Icons.person, _screenTitles[5]),
        ],
      ),
    );
  }
}