import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/global.dart';
import 'package:service_app/views/home_screen.dart';
import 'package:service_app/views/host_home.dart';
import 'package:service_app/views/login.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _hostingTitle = "Become a Host";
  String _userName = "";
  String _userEmail = "";
  ImageProvider? _profileImage;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateHostingTitle();
  }

  Future<void> _loadUserData() async {
    final user = AppConstants.currentUser;
    
    setState(() {
      _profileImage = null;
      _isLoadingImage = true;
      _userName = user.getFullNameofUser().isNotEmpty 
          ? user.getFullNameofUser()
          : "User Name";
      _userEmail = user.email?.toString() ?? "No email available";
    });

    try {
      final image = await user.getImageFromStorage();
      if (mounted) {
        setState(() {
          _profileImage = image ?? const AssetImage('assets/default_profile.png');
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileImage = const AssetImage('assets/default_profile.png');
          _isLoadingImage = false;
        });
      }
    }
  }

  void _updateHostingTitle() {
    setState(() {
      _hostingTitle = (AppConstants.currentUser.isHost ?? false)
          ? ((AppConstants.currentUser.isCurrentlyHosting ?? false)
              ? "Show my user Dashboard"
              : "Show my host Dashboard")
          : "Become a Host";
    });
  }

  Future<void> _modifyHostingMode() async {
    if (AppConstants.currentUser.isHost ?? false) {
      AppConstants.currentUser.isCurrentlyHosting = 
          !(AppConstants.currentUser.isCurrentlyHosting ?? false);
      Get.offAll(() => AppConstants.currentUser.isCurrentlyHosting! 
          ? HostHomeScreen() 
          : const HomeScreen());
    } else {
      await userViewModel.becomeHost(
        FirebaseAuth.instance.currentUser!.uid,
        AppConstants.currentUser,
      );
      AppConstants.currentUser.isHost = true;
      AppConstants.currentUser.isCurrentlyHosting = true;
      Get.offAll(() => HostHomeScreen());
    }
    _updateHostingTitle();
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('About This App'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'App Documentation ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
             Text(
  'Version: 1.0.3\n'
  'Developed by: Sandeep Kumar Swain (C.V Raman Global University)',
),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50, bottom: 30),
              child: Column(
                children: [
                  _isLoadingImage
                      ? CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: const CircularProgressIndicator(),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundImage: _profileImage,
                          backgroundColor: Colors.grey[200],
                          onBackgroundImageError: (_, __) => setState(() {
                            _profileImage = const AssetImage('assets/default_profile.png');
                          }),
                        ),
                  const SizedBox(height: 16),
                  Text(_userName, style: Theme.of(context).textTheme.titleLarge),
                  Text(_userEmail, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildButton("Personal Information", Icons.person, () {}),
        _buildButton(_hostingTitle, Icons.cleaning_services_rounded, _modifyHostingMode),
        _buildButton("Log Out", Icons.logout, () async {
          AppConstants.clearUserData();
          await FirebaseAuth.instance.signOut();
          Get.offAll(() => Login());
        }),
        _buildButton("Developed by", Icons.code, _showAboutDialog),
      ],
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
         colors: [Color(0xFF4A6CF7), Color(0xFF82C3FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(text, style: const TextStyle(color: Colors.white)),
        onTap: onPressed,
      ),
    );
  }
}