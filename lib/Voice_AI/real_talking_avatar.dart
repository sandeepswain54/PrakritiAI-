import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:async';

class RealTalkingAvatar extends StatefulWidget {
  final String avatarImagePath; // Your base avatar image
  
  const RealTalkingAvatar({Key? key, required this.avatarImagePath}) : super(key: key);

  @override
  _RealTalkingAvatarState createState() => _RealTalkingAvatarState();
}

class _RealTalkingAvatarState extends State<RealTalkingAvatar> 
    with TickerProviderStateMixin {
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _speechAvailable = false;
  String _text = '';
  List<ChatMessage> _messages = [];
  
  int _currentStep = 0;
  String _userName = '';
  Map<String, double> _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
  bool _showResults = false;

  // Animation for mouth states
  late AnimationController _mouthController;
  bool _isSpeaking = false;
  int _currentMouthState = 0; // 0=closed, 1=open1, 2=open2, 3=open3

  // Different mouth states for realistic talking
  final List<String> _mouthStates = [
    'assets/demo.png',    // Closed mouth
    'assets/demo_open1.jpeg',      // Slightly open
    'assets/demo_open2.jpeg',      // More open  
    'assets/demo_open3.jpeg',      // Fully open
  ];

  final List<String> _questions = [
    "Namaste! I'm Dhanvantri, your Ayurvedic health guide. What's your name?",
    "Nice to meet you! How would you describe your sleep quality?",
    "Thank you. How about your appetite and digestion?",
    "I see. How would you describe your energy levels throughout the day?",
    "Interesting. How do you handle stress?",
    "Last question - how would you describe your body type and skin?"
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize mouth animation
    _mouthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    )..addListener(() {
        // Cycle through mouth states based on animation value
        if (_isSpeaking) {
          setState(() {
            _currentMouthState = ((_mouthController.value * 3) % 4).floor();
          });
        }
      });
    
    _initializeApp();
  }

  void _initializeApp() async {
    _initSpeechRecognition();
    _initTTS();
    Future.delayed(Duration(seconds: 1), () {
      _startConversation();
    });
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
      await _flutterTts.setLanguage("en-US");
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
            _currentMouthState = 0; // Reset to closed mouth
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
        // Avatar with different mouth states - NO ANIMATEDSWITCHER
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(_mouthStates[_currentMouthState]),
              fit: BoxFit.fill,
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

        // Speaking Aura Effect
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
    if (_currentStep == 0) {
      _addMessage(_questions[0], false);
      _speak(_questions[0]);
    }
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
    
    switch (_currentStep) {
      case 0:
        _processName(text);
        break;
      case 1: case 2: case 3: case 4: case 5:
        _processDoshaQuestion(text);
        break;
    }
  }

  void _processName(String text) {
    String name = _extractName(text);
    if (name.isNotEmpty) {
      _userName = name;
      _currentStep = 1;
      _analyzeResponse(text, 0);
      
      _addMessage(_questions[1], false);
      _speak(_questions[1]);
    } else {
      _addMessage("Please tell me your name", false);
      _speak("Please tell me your name");
    }
  }

  void _processDoshaQuestion(String text) {
    _analyzeResponse(text, _currentStep);
    _currentStep++;
    
    if (_currentStep < _questions.length) {
      _addMessage(_questions[_currentStep], false);
      _speak(_questions[_currentStep]);
    } else {
      _calculateFinalDoshaScores();
      _showDoshaResults();
    }
  }

  void _analyzeResponse(String response, int questionIndex) {
    response = response.toLowerCase();
    
    if (response.contains('light sleeper') || response.contains('wake up') || response.contains('anxious')) {
      _doshaScores['vata'] = _doshaScores['vata']! + 20;
    }
    if (response.contains('deep sleep') || response.contains('hungry') || response.contains('focused')) {
      _doshaScores['pitta'] = _doshaScores['pitta']! + 20;
    }
    if (response.contains('heavy sleep') || response.contains('slow') || response.contains('calm')) {
      _doshaScores['kapha'] = _doshaScores['kapha']! + 20;
    }
  }

  void _calculateFinalDoshaScores() {
    double total = _doshaScores.values.reduce((a, b) => a + b);
    if (total > 0) {
      _doshaScores = _doshaScores.map((key, value) => 
        MapEntry(key, double.parse((value / total * 100).toStringAsFixed(0))));
    }
  }

  void _showDoshaResults() {
    String response = "Thank you! Based on our conversation, I've analyzed your dosha balance. Let me show you your results!";
    _addMessage(response, false);
    
    _speak(response).then((_) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) setState(() => _showResults = true);
      });
    });
  }

  String _getPrimaryDosha() {
    var sortedEntries = _doshaScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  String _extractName(String text) {
    text = text.toLowerCase();
    if (text.contains('my name is')) return text.split('my name is').last.trim();
    if (text.contains('i am')) return text.split('i am').last.trim();
    if (text.contains('i\'m')) return text.split('i\'m').last.trim();
    return text.isNotEmpty ? text : 'Friend';
  }

  Future<void> _speak(String text) async {
    try {
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
      _currentStep = 0;
      _userName = '';
      _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
      _showResults = false;
      _text = '';
      _currentMouthState = 0;
    });
    _startConversation();
  }

  Widget _buildDoshaResultsScreen() {
    String primaryDosha = _getPrimaryDosha();
    String primaryDoshaName = primaryDosha == 'vata' ? 'Vata' : 
                              primaryDosha == 'pitta' ? 'Pitta' : 'Kapha';
    
    Map<String, String> doshaDescriptions = {
      'vata': 'Space + Air\n\nSpontaneous • Enthusiastic • Creative • Flexible • Energetic',
      'pitta': 'Fire + Water\n\nFocused • Determined • Intelligent • Leadership • Ambitious', 
      'kapha': 'Earth + Water\n\nCalm • Grounded • Nurturing • Strong • Patient'
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 60),
            Text('Your Results', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            Text('Your ideal balance', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDoshaCircle('Body', _doshaScores['vata']!, Colors.blue),
                _buildDoshaCircle('Metabolism', _doshaScores['pitta']!, Colors.orange),
                _buildDoshaCircle('Mind', _doshaScores['kapha']!, Colors.green),
              ],
            ),
            
            SizedBox(height: 50),
            Text('Your predominant dosha is', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 10),
            Text(primaryDoshaName, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _getDoshaColor(primaryDosha))),
            SizedBox(height: 40),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getDoshaColor(primaryDosha).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getDoshaColor(primaryDosha), width: 2),
              ),
              child: Column(
                children: [
                  Text(primaryDoshaName.toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getDoshaColor(primaryDosha))),
                  SizedBox(height: 15),
                  Text(doshaDescriptions[primaryDosha]!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.4)),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: _getDoshaColor(primaryDosha), padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  child: Text('Know More >', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: _resetConversation,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  child: Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaCircle(String label, double percentage, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 90, height: 90, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color, width: 4))),
            Text('${percentage.toInt()}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SizedBox(height: 15),
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getDoshaColor(String dosha) {
    switch (dosha) {
      case 'vata': return Colors.blue;
      case 'pitta': return Colors.orange;
      case 'kapha': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) return _buildDoshaResultsScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Dhanvantri AI 🍃', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        actions: [IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: _resetConversation)],
      ),
      body: Column(
        children: [
          // SMALLER CONTAINER HEIGHT
          Container(height: 220, child: Center(child: _buildTalkingAvatar())),
          Container(padding: EdgeInsets.symmetric(vertical: 12), color: _speechAvailable ? Colors.green[50] : Colors.orange[50],
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_speechAvailable ? Icons.check_circle : Icons.warning, color: _speechAvailable ? Colors.green : Colors.orange),
              SizedBox(width: 8), Text(_speechAvailable ? 'Ready for conversation' : 'Microphone required'),
            ]),
          ),
          Expanded(
            child: _messages.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.health_and_safety, size: 70, color: Colors.grey[300]),
              SizedBox(height: 20), Text('Ayurvedic Health Analysis', style: TextStyle(color: Colors.grey, fontSize: 18)),
              SizedBox(height: 10), Text('Speak with Dhanvantri AI', style: TextStyle(color: Colors.grey)),
            ])) : ListView.builder(padding: EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (context, index) {
              return ChatBubble(message: _messages[index].text, isUser: _messages[index].isUser);
            }),
          ),
          if (_isListening) Container(padding: EdgeInsets.all(16), child: Column(children: [
            Text("Listening...", style: TextStyle(color: Colors.blue)), SizedBox(height: 10), CircularProgressIndicator(),
          ])),
          if (_text.isNotEmpty) Container(padding: EdgeInsets.all(16), child: Text(_text, textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic))),
        ],
      ),
      floatingActionButton: AvatarGlow(
        animate: _isListening, glowColor: Colors.green, duration: Duration(milliseconds: 2000), repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 30, color: Colors.white),
          backgroundColor: _isListening ? Colors.red : Colors.green,
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
    return Container(margin: EdgeInsets.symmetric(vertical: 8), child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) Container(margin: EdgeInsets.only(right: 8), child: CircleAvatar(backgroundColor: Colors.green[100], child: Icon(Icons.face, color: Colors.green), radius: 18)),
        Flexible(child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(
          color: isUser ? Color(0xFF2E7D32) : Colors.green[50], borderRadius: BorderRadius.circular(20)),
          child: Text(message, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16)),
        )),
      ],
    ));
  }
}