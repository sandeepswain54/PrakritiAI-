import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:async';

class RealisticDhanvantriAvatar extends StatefulWidget {
  @override
  _RealisticDhanvantriAvatarState createState() => _RealisticDhanvantriAvatarState();
}

class _RealisticDhanvantriAvatarState extends State<RealisticDhanvantriAvatar> 
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

  // Animation controllers for realistic avatar
  late AnimationController _mouthController;
  late AnimationController _blinkController;
  late AnimationController _idleController;
  bool _isSpeaking = false;
  bool _isBlinking = false;

  // Questions for dosha analysis
  final List<String> _questions = [
    "Namaste! I'm Dhanvantri, your Ayurvedic health guide. What's your name?",
    "Nice to meet you! How would you describe your sleep quality? Do you sleep deeply or wake up frequently?",
    "Thank you. How about your appetite and digestion? Do you feel hungry often or have digestive issues?",
    "I see. How would you describe your energy levels throughout the day? Consistent or do you have ups and downs?",
    "Interesting. How do you handle stress? Do you feel anxious, angry, or tend to avoid situations?",
    "Last question - how would you describe your body type and skin condition? Lean and dry, medium and warm, or heavier and moist?"
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _mouthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    
    _idleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _initializeApp();
    _startBlinking();
  }

  void _startBlinking() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted && !_isSpeaking) {
        setState(() => _isBlinking = true);
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isBlinking = false);
        });
      }
    });
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
      print("Speech initialization failed: $e");
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  void _initTTS() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      
      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _mouthController.repeat(reverse: true);
          });
        }
      });
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _mouthController.stop();
          });
        }
      });
      
    } catch (e) {
      print("Error initializing TTS: $e");
    }
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

    if (!_speechAvailable) {
      await _requestSpeechPermission();
      return;
    }

    await _startListening();
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _requestSpeechPermission() async {
    try {
      bool hasSpeech = await _speech.initialize();
      if (hasSpeech && mounted) {
        setState(() => _speechAvailable = true);
        await _startListening();
      }
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_speechAvailable || _isListening) return;

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
        pauseFor: Duration(seconds: 5),
      );
      
    } catch (e) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _processSpeech(String text) {
    _addMessage(text, true);
    
    switch (_currentStep) {
      case 0:
        _processName(text);
        break;
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
        _processDoshaQuestion(text);
        break;
      default:
        _processGeneralResponse(text);
    }
  }

  void _processName(String text) {
    String name = _extractName(text);
    if (name.isNotEmpty) {
      _userName = name;
      _currentStep = 1;
      _analyzeResponse(text, 0);
      
      String response = _questions[1];
      _addMessage(response, false);
      _speak(response);
    } else {
      String response = "I didn't catch your name. Could you please tell me your name?";
      _addMessage(response, false);
      _speak(response);
    }
  }

  void _processDoshaQuestion(String text) {
    _analyzeResponse(text, _currentStep);
    _currentStep++;
    
    if (_currentStep < _questions.length) {
      String nextQuestion = _questions[_currentStep];
      _addMessage(nextQuestion, false);
      _speak(nextQuestion);
    } else {
      _calculateFinalDoshaScores();
      _showDoshaResults();
    }
  }

  void _analyzeResponse(String response, int questionIndex) {
    response = response.toLowerCase();
    
    // Vata indicators
    if (response.contains('light sleeper') || response.contains('wake up') || 
        response.contains('insomnia') || response.contains('anxious') ||
        response.contains('variable') || response.contains('dry') ||
        response.contains('lean') || response.contains('creative')) {
      _doshaScores['vata'] = _doshaScores['vata']! + 20;
    }
    
    // Pitta indicators  
    if (response.contains('deep sleep') || response.contains('hungry') ||
        response.contains('strong appetite') || response.contains('focused') ||
        response.contains('perfectionist') || response.contains('warm') ||
        response.contains('medium') || response.contains('leadership')) {
      _doshaScores['pitta'] = _doshaScores['pitta']! + 20;
    }
    
    // Kapha indicators
    if (response.contains('heavy sleep') || response.contains('slow digestion') ||
        response.contains('steady') || response.contains('calm') ||
        response.contains('avoid') || response.contains('moist') ||
        response.contains('heavy') || response.contains('patient')) {
      _doshaScores['kapha'] = _doshaScores['kapha']! + 20;
    }
  }

  void _calculateFinalDoshaScores() {
    // Ensure total is 100%
    double total = _doshaScores.values.reduce((a, b) => a + b);
    if (total > 0) {
      _doshaScores = _doshaScores.map((key, value) => 
        MapEntry(key, double.parse((value / total * 100).toStringAsFixed(0))));
    }
  }

  void _showDoshaResults() {
    String response = "Thank you for sharing! Based on our conversation, I've analyzed your Ayurvedic constitution. Let me show you your dosha results!";
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

  void _processGeneralResponse(String text) {
    String response = "Thank you for sharing that information.";
    _addMessage(response, false);
    _speak(response);
  }

  String _extractName(String text) {
    text = text.toLowerCase();
    if (text.contains('my name is')) {
      return text.split('my name is').last.trim();
    } else if (text.contains('i am')) {
      return text.split('i am').last.trim();
    } else if (text.contains('i\'m')) {
      return text.split('i\'m').last.trim();
    }
    return text.isNotEmpty ? text : 'Friend';
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error in TTS: $e");
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
    });
    _startConversation();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildRealisticAvatar() {
    return Container(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Avatar Background
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[100]!, Colors.green[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          ),

          // Face Container
          Container(
            width: 160,
            height: 180,
            child: Stack(
              children: [
                // Head shape
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    width: 120,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                ),

                // Eyes
                Positioned(
                  top: 50,
                  left: 35,
                  child: _buildEye(left: true),
                ),
                Positioned(
                  top: 50,
                  left: 85,
                  child: _buildEye(left: false),
                ),

                // Nose
                Positioned(
                  top: 80,
                  left: 75,
                  child: Container(
                    width: 10,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.brown[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),

                // Mouth with animation
                Positioned(
                  top: 110,
                  left: 50,
                  child: AnimatedBuilder(
                    animation: _mouthController,
                    builder: (context, child) {
                      return Container(
                        width: 60,
                        height: _isSpeaking ? (10 + _mouthController.value * 8) : 4,
                        decoration: BoxDecoration(
                          color: Colors.red[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),

                // Eyebrows with idle animation
                Positioned(
                  top: 45,
                  left: 35,
                  child: AnimatedBuilder(
                    animation: _idleController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _idleController.value * 2 - 1),
                        child: Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.brown[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 45,
                  left: 85,
                  child: AnimatedBuilder(
                    animation: _idleController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _idleController.value * 2 - 1),
                        child: Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.brown[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Traditional Ayurvedic mark on forehead
                Positioned(
                  top: 35,
                  left: 75,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ayurvedic aura effect
          if (_isSpeaking)
            Positioned(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEye({bool left = true}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      width: _isBlinking ? 20 : 25,
      height: _isBlinking ? 2 : 12,
      decoration: BoxDecoration(
        color: _isBlinking ? Colors.transparent : Colors.brown[800],
        borderRadius: BorderRadius.circular(10),
        border: _isBlinking ? null : Border.all(color: Colors.black, width: 2),
      ),
      child: _isBlinking ? null : Container(
        alignment: Alignment(0.3, 0),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
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
            
            Text(
              'Your Results',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: 30),
            
            Text(
              'Your ideal balance',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Dosha percentages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDoshaCircle('Body', _doshaScores['vata']!, Colors.blue),
                _buildDoshaCircle('Metabolism', _doshaScores['pitta']!, Colors.orange),
                _buildDoshaCircle('Mind', _doshaScores['kapha']!, Colors.green),
              ],
            ),
            
            SizedBox(height: 50),
            
            Text(
              'Your predominant dosha is',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 10),
            
            Text(
              primaryDoshaName,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: _getDoshaColor(primaryDosha),
              ),
            ),
            
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
                  Text(
                    primaryDoshaName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getDoshaColor(primaryDosha),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    doshaDescriptions[primaryDosha]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Know More action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getDoshaColor(primaryDosha),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Know More >',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                ElevatedButton(
                  onPressed: _resetConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
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
    if (_showResults) {
      return _buildDoshaResultsScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Dhanvantri AI 🍃',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: 26),
            onPressed: _resetConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Realistic Avatar Section
          Container(
            height: 300,
            child: Center(
              child: _buildRealisticAvatar(),
            ),
          ),
          
          // Status Indicator
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            color: _speechAvailable ? Colors.green[50] : Colors.orange[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _speechAvailable ? Icons.check_circle : Icons.warning,
                  color: _speechAvailable ? Colors.green : Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  _speechAvailable ? 'Ready for conversation' : 'Microphone access required',
                  style: TextStyle(
                    color: _speechAvailable ? Colors.green : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.health_and_safety, 
                          size: 70, 
                          color: Colors.grey[300]
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Ayurvedic Health Analysis',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Speak with Dhanvantri AI',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
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
          
          // Listening Indicator
          if (_isListening)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Listening...",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
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
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
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
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _blinkController.dispose();
    _idleController.dispose();
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