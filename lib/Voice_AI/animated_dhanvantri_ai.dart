import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class AnimatedDhanvantriAI extends StatefulWidget {
  @override
  _AnimatedDhanvantriAIState createState() => _AnimatedDhanvantriAIState();
}

class _AnimatedDhanvantriAIState extends State<AnimatedDhanvantriAI> 
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
  List<String> _userSymptoms = [];
  List<String> _conversationHistory = [];

  // Animation controllers
  late AnimationController _mouthController;
  late AnimationController _avatarController;
  bool _isSpeaking = false;
  bool _showResults = false;

  // Questions to analyze doshas
  final List<Map<String, dynamic>> _doshaQuestions = [
    {
      'question': 'How is your sleep quality? Do you have difficulty falling asleep or wake up frequently?',
      'vata_keywords': ['difficulty', 'light sleeper', 'wake up', 'insomnia', 'restless'],
      'pitta_keywords': ['deep sleep', 'dreams', 'warm', 'wake up hot'],
      'kapha_keywords': ['heavy sleep', 'deep sleep', 'hard to wake', 'lethargic']
    },
    {
      'question': 'Describe your appetite and digestion. How is your hunger throughout the day?',
      'vata_keywords': ['irregular', 'variable', 'bloating', 'gas', 'constipation'],
      'pitta_keywords': ['strong', 'sharp', 'hungry', 'acidity', 'heartburn'],
      'kapha_keywords': ['slow', 'steady', 'low hunger', 'heavy after meals']
    },
    {
      'question': 'How would you describe your energy levels and mood throughout the day?',
      'vata_keywords': ['variable', 'bursts', 'anxious', 'creative', 'enthusiastic'],
      'pitta_keywords': ['intense', 'focused', 'irritable', 'perfectionist'],
      'kapha_keywords': ['steady', 'calm', 'lethargic', 'peaceful', 'slow']
    },
    {
      'question': 'What about your skin and body temperature? How do they feel?',
      'vata_keywords': ['dry', 'cold', 'rough', 'cracked'],
      'pitta_keywords': ['warm', 'oily', 'sensitive', 'rashes'],
      'kapha_keywords': ['cool', 'moist', 'smooth', 'oily']
    },
    {
      'question': 'How do you handle stress and what are your main health concerns?',
      'vata_keywords': ['worry', 'anxiety', 'nervous', 'overthinking'],
      'pitta_keywords': ['anger', 'frustration', 'impatience', 'perfectionism'],
      'kapha_keywords': ['avoidance', 'withdrawal', 'attachment', 'slow to change']
    }
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _mouthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    
    _avatarController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
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
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );

      if (mounted) {
        setState(() {
          _speechAvailable = hasSpeech;
        });
      }
    } catch (e) {
      print("Speech initialization failed: $e");
      if (mounted) {
        setState(() => _speechAvailable = false);
      }
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

  void _startConversation() async {
    if (_currentStep == 0) {
      String greeting = "Namaste! I'm Dhanvantri AI, your Ayurvedic health guide. What's your name?";
      _addMessage(greeting, false);
      await _speak(greeting);
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
          if (mounted) {
            setState(() {
              _text = result.recognizedWords;
            });
          }
          
          if (result.finalResult) {
            _processSpeech(result.recognizedWords);
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        cancelOnError: true,
        partialResults: true,
      );
      
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _processSpeech(String text) {
    _addMessage(text, true);
    _conversationHistory.add(text.toLowerCase());
    
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
      
      String response = "Nice to meet you, $name! Let me ask you a few questions to understand your dosha balance. ${_doshaQuestions[0]['question']}";
      _addMessage(response, false);
      _speak(response);
    } else {
      String response = "I didn't catch your name. Could you please tell me your name?";
      _addMessage(response, false);
      _speak(response);
    }
  }

  void _processDoshaQuestion(String text) {
    // Analyze the response for dosha indicators
    _analyzeResponseForDosha(text.toLowerCase());
    
    // Move to next question or show results
    if (_currentStep < _doshaQuestions.length) {
      _currentStep++;
      
      if (_currentStep < _doshaQuestions.length) {
        String nextQuestion = _doshaQuestions[_currentStep]['question'];
        _addMessage(nextQuestion, false);
        _speak(nextQuestion);
      } else {
        // All questions answered - calculate final dosha scores
        _calculateFinalDoshaScores();
        _showDoshaResults();
      }
    }
  }

  void _analyzeResponseForDosha(String response) {
    if (_currentStep - 1 < _doshaQuestions.length) {
      var currentQuestion = _doshaQuestions[_currentStep - 1];
      
      // Check for Vata keywords
      for (String keyword in currentQuestion['vata_keywords']) {
        if (response.contains(keyword)) {
          _doshaScores['vata'] = _doshaScores['vata']! + 20;
        }
      }
      
      // Check for Pitta keywords
      for (String keyword in currentQuestion['pitta_keywords']) {
        if (response.contains(keyword)) {
          _doshaScores['pitta'] = _doshaScores['pitta']! + 20;
        }
      }
      
      // Check for Kapha keywords
      for (String keyword in currentQuestion['kapha_keywords']) {
        if (response.contains(keyword)) {
          _doshaScores['kapha'] = _doshaScores['kapha']! + 20;
        }
      }
    }
  }

  void _calculateFinalDoshaScores() {
    // Add some randomness to make it realistic
    Random random = Random();
    
    // Base scores from conversation analysis
    double vataBase = _doshaScores['vata']!;
    double pittaBase = _doshaScores['pitta']!;
    double kaphaBase = _doshaScores['kapha']!;
    
    // Add some variation
    _doshaScores['vata'] = (vataBase + random.nextInt(20)).clamp(0.0, 100.0);
    _doshaScores['pitta'] = (pittaBase + random.nextInt(20)).clamp(0.0, 100.0);
    _doshaScores['kapha'] = (kaphaBase + random.nextInt(20)).clamp(0.0, 100.0);
    
    // Normalize to 100%
    double total = _doshaScores.values.reduce((a, b) => a + b);
    if (total > 0) {
      _doshaScores = _doshaScores.map((key, value) => 
        MapEntry(key, double.parse((value / total * 100).toStringAsFixed(0))));
    }
  }

  void _showDoshaResults() {
    String primaryDosha = _getPrimaryDosha();
    String response = "Based on our conversation, I've analyzed your dosha balance. Let me show you your results!";
    _addMessage(response, false);
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showResults = true;
        });
      }
    });
  }

  String _getPrimaryDosha() {
    var sortedEntries = _doshaScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  void _processGeneralResponse(String text) {
    String response = "Thank you for sharing! Let me analyze this information for your dosha balance.";
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
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  void _resetConversation() {
    setState(() {
      _messages.clear();
      _currentStep = 0;
      _userName = '';
      _userSymptoms.clear();
      _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
      _conversationHistory.clear();
      _showResults = false;
      _text = '';
    });
    _startConversation();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDhanvantriAvatar() {
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base avatar (you can replace with your Dhanvantri image)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 3),
            ),
            child: Icon(
              Icons.face,
              size: 80,
              color: Colors.green[800],
            ),
          ),
          
          // Animated mouth
          if (_isSpeaking)
            Positioned(
              bottom: 40,
              child: AnimatedBuilder(
                animation: _mouthController,
                builder: (context, child) {
                  return Container(
                    width: 30 + (_mouthController.value * 10),
                    height: 10 + (_mouthController.value * 5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
        ],
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

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          
          Text(
            'Your Results',
            style: TextStyle(
              fontSize: 28,
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
          
          // Dosha percentages in circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDoshaCircle('Body', _doshaScores['vata']!, Colors.blue),
              _buildDoshaCircle('Metabolism', _doshaScores['pitta']!, Colors.orange),
              _buildDoshaCircle('Mind', _doshaScores['kapha']!, Colors.green),
            ],
          ),
          
          SizedBox(height: 40),
          
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getDoshaColor(primaryDosha),
            ),
          ),
          
          SizedBox(height: 30),
          
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getDoshaColor(primaryDosha).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _getDoshaColor(primaryDosha)),
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
                SizedBox(height: 10),
                Text(
                  doshaDescriptions[primaryDosha]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
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
                ),
                child: Text(
                  'Know More >',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showResults = false;
                    _resetConversation();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
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
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetConversation,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Avatar Section
            Container(
              height: 200,
              child: Center(
                child: _buildDhanvantriAvatar(),
              ),
            ),
            
            // Status Indicator
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              color: _speechAvailable ? Colors.green[50] : Colors.orange[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _speechAvailable ? Icons.check_circle : Icons.warning,
                    color: _speechAvailable ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _speechAvailable ? 'Ready to listen' : 'Microphone required',
                    style: TextStyle(
                      color: _speechAvailable ? Colors.green : Colors.orange,
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
                          Icon(Icons.health_and_safety, size: 64, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'Ayurvedic Health Analysis',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tell me about your health',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
                    Text("Listening...", style: TextStyle(color: Colors.blue)),
                    SizedBox(height: 8),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            
            if (_text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                child: Text(_text, style: TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.green,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 30),
          backgroundColor: _isListening ? Colors.red : Colors.green,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _avatarController.dispose();
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
                radius: 16,
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF2E7D32) : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}