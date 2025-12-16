// ghar_ke_nuske_ai_updated.dart
import 'package:flutter/material.dart';
import 'package:service_app/Voice_AI/remedy_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class GharKeNuskeAI extends StatefulWidget {
  final String avatarImagePath;
  
  const GharKeNuskeAI({Key? key, required this.avatarImagePath}) : super(key: key);

  @override
  _GharKeNuskeAIState createState() => _GharKeNuskeAIState();
}

class _GharKeNuskeAIState extends State<GharKeNuskeAI> with TickerProviderStateMixin {
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _speechAvailable = false;
  String _text = '';
  List<ChatMessage> _messages = [];
  
  bool _showResults = false;
  late AnimationController _mouthController;
  bool _isSpeaking = false;
  int _currentMouthState = 0;

  // Different mouth states
  final List<String> _mouthStates = [
    'assets/demo.png',
    'assets/demo_open1.jpeg', 
    'assets/demo_open2.jpeg',  
    'assets/demo_open3.jpeg',
  ];

  String _csvData = '';

  @override
  void initState() {
    super.initState();
    
    _mouthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    )..addListener(() {
        if (_isSpeaking) {
          setState(() {
            _currentMouthState = ((_mouthController.value * 3) % 4).floor();
          });
        }
      });
    
    _initializeApp();
  }

  void _initializeApp() async {
    await _loadCSVData();
    _initSpeechRecognition();
    _initTTS();
    
    Future.delayed(Duration(seconds: 1), () {
      _startConversation();
    });
  }

  Future<void> _loadCSVData() async {
    try {
      _csvData = await rootBundle.loadString('assets/AyurGenixAI_Dataset.csv');
      await RemedyService.initializeWithCSV(_csvData);
      print('✅ CSV data loaded successfully');
    } catch (e) {
      print('❌ Error loading CSV: $e');
      // Fallback to basic remedies
      _csvData = '';
    }
  }

  void _initSpeechRecognition() async {
    try {
      bool hasSpeech = await _speech.initialize(
        onStatus: (status) {
          if (mounted && status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() => _speechAvailable = hasSpeech);
    } catch (e) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  void _initTTS() async {
    try {
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      
      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _mouthController.repeat();
          });
        }
      });
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _mouthController.stop();
            _currentMouthState = 0;
          });
        }
      });
      
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  Widget _buildTalkingAvatar() {
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(_mouthStates[_currentMouthState]),
                fit: BoxFit.contain,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          ),

          if (_isSpeaking)
            Positioned(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.6),
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startConversation() {
    String greeting = "नमस्ते बेटा! मैं आयुर्वेदिक सलाहकार हूं। कोई स्वास्थ्य समस्या है? बोलकर बताओ, मैं आयुर्वेदिक उपचार बताती हूं। जैसे: 'खांसी है', 'मधुमेह', 'ब्लड प्रेशर', 'जोड़ों का दर्द'";
    _addMessage(greeting, false);
    _speak(greeting);
  }

  void _listen() async {
    if (_isListening) {
      _stopListening();
      return;
    }
    if (!_speechAvailable) return;
    
    setState(() {
      _isListening = true;
      _text = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) setState(() => _text = result.recognizedWords);
        if (result.finalResult) {
          _processSpeech(result.recognizedWords);
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenFor: Duration(seconds: 30),
    );
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _processSpeech(String text) {
    _addMessage(text, true);
    _findRemedies(text);
  }

  void _findRemedies(String userQuery) async {
    try {
      // Show loading message
      _addMessage("आयुर्वेदिक उपचार ढूंढ रही हूं... 🌿", false);
      
      // Extract symptoms using NLP from CSV data
      List<String> symptoms = await RemedyService.extractSymptoms(userQuery);
      
      // Get verified remedies from CSV
      List<Map<String, dynamic>> remedies = await RemedyService.getRemediesForSymptoms(symptoms);
      
      // Generate friendly response
      String response = RemedyService.generateFriendlyResponse(remedies, userQuery);
      
      // Remove loading message and add actual response
      setState(() {
        _messages.removeLast(); // Remove loading message
      });
      
      _addMessage(response, false);
      _speak(response);
      
    } catch (e) {
      String errorMsg = "अरे बेटा! कुछ गड़बड़ हो गया। कृपया फिर से कोशिश करें।";
      _addMessage(errorMsg, false);
      _speak(errorMsg);
      print("Error finding remedies: $e");
    }
  }

  Future<void> _speak(String text) async {
    try {
      // Auto-detect language and set TTS language
      await _flutterTts.setLanguage("hi-IN");

      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: isUser)));
  }

  void _resetConversation() {
    setState(() {
      _messages.clear();
      _showResults = false;
      _text = '';
      _currentMouthState = 0;
    });
    _startConversation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('आयुर्वेदिक सलाहकार 🌿', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white), 
            onPressed: _resetConversation,
            tooltip: 'नया संवाद शुरू करें',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 220, 
            child: Center(
              child: _buildTalkingAvatar(),
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(vertical: 12), 
            color: _speechAvailable ? Colors.green[50] : Colors.orange[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _speechAvailable ? Icons.check_circle : Icons.warning,
                  color: _speechAvailable ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  _speechAvailable ? 'बोलिए, मैं सुन रही हूं 👵' : 'माइक्रोफोन की आवश्यकता है',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _messages.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.health_and_safety, 
                          size: 70, 
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'आयुर्वेदिक स्वास्थ्य सलाहकार 👵',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'बोलकर अपनी समस्या बताएं\nजैसे: "खांसी है", "मधुमेह", "ब्लड प्रेशर"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        message: _messages[index].text,
                        isUser: _messages[index].isUser,
                      );
                    },
                  ),
          ),
          
          if (_isListening)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "सुन रही हूं... 👂",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          
          if (_text.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                _text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
      
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.green,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 30,
            color: Colors.white,
          ),
          backgroundColor: _isListening ? Colors.red : Colors.green,
          tooltip: 'बोलकर बताएं',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({Key? key, required this.message, required this.isUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.face, color: Colors.green),
                radius: 18,
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF2E7D32) : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}