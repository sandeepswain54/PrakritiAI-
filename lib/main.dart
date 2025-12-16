import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:service_app/FLASK%20API/tongue_api_service.dart';
import 'package:service_app/Frontend_Flutter/ayurhome.dart';
import 'package:service_app/Prakriti_Chatbot/chat_provider.dart';
import 'package:service_app/Prakriti_Chatbot/chat_service.dart';                                                                                                                                                                                                                                                                                                                                                     
import 'package:service_app/Voice_AI/assets_avatar_lipsync.dart';
import 'package:service_app/Voice_AI/ghar_ke_nuske_ai.dart';
import 'package:service_app/Voice_AI/real_talking_avatar.dart';
import 'package:service_app/views/Host_Screens/Home_Screen.dart';
import 'package:service_app/views/splash_screen.dart';

import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Load environment variables
    await loadEnvFromAssets();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ChatProvider(TogetherAIService()),
          ),
          // CartProvider used across the app (shopping cart)
         
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Initialization Error', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                Text(e.toString()),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> loadEnvFromAssets() async {
  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint('Environment loaded from assets');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    await dotenv.load(fileName: "assets/.env", mergeWith: {
      'TOGETHER_API_KEY': '',
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Service App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/ghar-ke-nuske': (context) => GharKeNuskeAI(
              avatarImagePath: 'assets/demo.png',
            ),
      },
    );
  }
}
