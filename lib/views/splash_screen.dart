import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/views/host_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

import 'package:service_app/views/onboarding_screen.dart';
import 'package:service_app/views/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    
    // Timeout: If video doesn't load in 10 seconds, navigate anyway
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_isVideoReady) {
        debugPrint('Video loading timeout - navigating to next screen');
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/ayu2.mp4');
      await _controller.initialize();
      
      if (mounted) {
        _controller.setLooping(false);
        _controller.setVolume(1);
        await _controller.play();

        setState(() {
          _isVideoReady = true;
        });

        // Navigate after video ends
        final duration = _controller.value.duration;
        debugPrint('Playing video: assets/yukti23.mp4, Duration: $duration');
        
        Future.delayed(duration, () {
          if (mounted) {
            _navigateToNextScreen();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
      // If video fails to load, navigate immediately
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (!seenOnboarding) {
      await prefs.setBool('seenOnboarding', true);
      Get.offAll(() => const OnboardingScreenPage());
    } else if (user != null) {
      Get.offAll(() =>  HostHomeScreen());
    } else {
      Get.offAll(() => const OnboardingScreenPage());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
