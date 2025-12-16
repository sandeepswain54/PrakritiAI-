// voice_ai_ayurveda.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';

class VoiceAIAyurvedaPage extends StatefulWidget {
  @override
  _VoiceAIAyurvedaPageState createState() => _VoiceAIAyurvedaPageState();
}

class _VoiceAIAyurvedaPageState extends State<VoiceAIAyurvedaPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _speechAvailable = false;
  String _text = '';
  String _currentLanguage = 'en-US';
  List<ChatMessage> _messages = [];
  
  int _currentStep = 0;
  String _userName = '';
  Map<String, double> _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
  List<String> _userSymptoms = [];

  final Map<String, String> _languages = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
  };

  @override
  void initState() {
    super.initState();
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
      print("🔄 Initializing speech recognition...");
      
      bool hasSpeech = false;
      try {
        hasSpeech = await _speech.initialize(
          onStatus: (status) {
            print('📱 Speech Status: $status');
            if (mounted) {
              if (status == 'notListening') {
                setState(() => _isListening = false);
              }
            }
          },
          onError: (error) {
            print('❌ Speech Error: $error');
            if (mounted) {
              setState(() => _isListening = false);
            }
          },
        );
      } on Exception catch (e) {
        print("⚠️ Speech initialization failed: $e");
        hasSpeech = false;
      }

      if (mounted) {
        setState(() {
          _speechAvailable = hasSpeech;
        });
      }
    } catch (e) {
      print("❌ Critical error initializing speech: $e");
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
    } catch (e) {
      print("Error initializing TTS: $e");
    }
  }

  void _startConversation() async {
    if (_currentStep == 0) {
      String greeting = _getGreeting();
      _addMessage(greeting, false);
      await _speak(greeting);
    }
  }

  String _getGreeting() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'नमस्ते! मैं धन्वंतरी AI हूं, आपका आयुर्वेदिक स्वास्थ्य सहायक। आपका क्या नाम है?';
      case 'ta-IN':
        return 'வணக்கம்! நான் தhan்வந்தரி AI, உங்கள் ஆயுர்வேத சுகாதார உதவியாளர். உங்கள் பெயர் என்ன?';
      case 'te-IN':
        return 'నమస్కారం! నేను ధన్వంతరి AI, మీ ఆయుర్వేద ఆరోగ్య సహాయకుడు. మీ పేరు ఏమిటి?';
      default:
        return 'Namaste! I\'m Dhanvantri AI, your Ayurvedic health assistant. What\'s your name?';
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
      bool hasSpeech = await _speech.initialize(
        debugLogging: false,
        onStatus: (status) => print('📱 Speech Status: $status'),
        onError: (error) => print('❌ Speech Error: $error'),
      );
      
      if (hasSpeech && mounted) {
        setState(() => _speechAvailable = true);
        await _startListening();
      } else {
        _showPermissionDeniedMessage();
      }
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_speechAvailable) {
        await _requestSpeechPermission();
        return;
      }

      if (_isListening) return;

      if (mounted) {
        setState(() {
          _isListening = true;
          _text = '';
        });
      }

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
        localeId: _currentLanguage,
        cancelOnError: true,
        partialResults: true,
      );
      
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
      }
      _showErrorMessage('Failed to start listening: ${e.toString()}');
    }
  }

  void _processSpeech(String text) {
    _addMessage(text, true);
    
    switch (_currentStep) {
      case 0:
        _processName(text);
        break;
      case 1:
        _processAge(text);
        break;
      case 2:
        _processSymptoms(text);
        break;
      case 3:
        _processLifestyle(text);
        break;
      case 4:
        _processDoshaAnalysis(text);
        break;
      case 5:
        _processRemedySelection(text);
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
      
      String response = _getNameResponse(name);
      _addMessage(response, false);
      _speak(response);
    } else {
      String response = _getNoNameResponse();
      _addMessage(response, false);
      _speak(response);
    }
  }

  String _getNameResponse(String name) {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'बहुत खूब $name! आपसे मिलकर बहुत खुशी हुई। कृपया मुझे अपनी उम्र बताएं ताकि मैं आपको बेहतर आयुर्वेदिक सलाह दे सकूं।';
      case 'ta-IN':
        return 'அருமை $name! உங்களை சந்தித்ததில் மிக்க மகிழ்ச்சி. தயவு செய்து உங்கள் வயதைச் சொல்லுங்கள், நான் உங்களுக்கு சிறந்த ஆயுர்வேத ஆலோசனை வழங்க முடியும்.';
      case 'te-IN':
        return 'చాలా బాగుంది $name! మిమ్మల్ని కలిసినందుకు చాలా సంతోషం. దయచేసి మీ వయస్సు చెప్పండి, నేను మీకు మంచి ఆయుర్వేద సలహా ఇవ్వగలను.';
      default:
        return 'Wonderful $name! It\'s great to meet you. Please tell me your age so I can provide better Ayurvedic guidance.';
    }
  }

  String _getNoNameResponse() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'मुझे आपका नाम समझ नहीं आया। क्या आप कृपया अपना नाम फिर से बता सकते हैं?';
      case 'ta-IN':
        return 'உங்கள் பெயரை நான் புரிந்து கொள்ளவில்லை. தயவு செய்து உங்கள் பெயரை மீண்டும் சொல்ல முடியுமா?';
      case 'te-IN':
        return 'నేను మీ పేరు అర్థం చేసుకోలేదు. దయచేసి మీ పేరును మళ్లీ చెప్పగలరా?';
      default:
        return 'I didn\'t quite catch your name. Could you please say it again?';
    }
  }

  void _processAge(String text) {
    int? age = _extractAge(text);
    _currentStep = 2;
    
    String response = _getAgeResponse(age);
    _addMessage(response, false);
    _speak(response);
  }

  int? _extractAge(String text) {
    try {
      RegExp regExp = RegExp(r'\b(\d{1,2})\b');
      var matches = regExp.allMatches(text);
      if (matches.isNotEmpty) {
        return int.tryParse(matches.first.group(1)!);
      }
    } catch (e) {
      print("Error extracting age: $e");
    }
    return null;
  }

  String _getAgeResponse(int? age) {
    String ageText = age != null ? age.toString() : '';
    
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'धन्यवाद! अब कृपया मुझे बताएं कि आप किन स्वास्थ्य समस्याओं का सामना कर रहे हैं? जैसे सिरदर्द, नींद न आना, पाचन समस्या, तनाव आदि।';
      case 'ta-IN':
        return 'நன்றி! இப்போது தயவு செய்து நீங்கள் எந்த சுகாதார பிரச்சினைகளை எதிர்கொள்கிறீர்கள் என்று சொல்லுங்கள்? தலைவலி, தூக்கம் இல்லாமை, செரிமான பிரச்சினை, மன அழுத்தம் போன்றவை.';
      case 'te-IN':
        return 'ధన్యవాదాలు! ఇప్పుడు దయచేసి మీరు ఏ ఆరోగ్య సమస్యలను ఎదుర్కొంటున్నారో చెప్పండి? తలనొప్పి, నిద్రలేమి, జీర్ణక్రియ సమస్య, ఒత్తిడి వంటివి.';
      default:
        return 'Thank you! Now please tell me what health issues you\'re facing? Like headache, insomnia, digestion problems, stress etc.';
    }
  }

  void _processSymptoms(String text) {
    // Extract symptoms using NLP
    List<String> symptoms = _extractSymptoms(text);
    _userSymptoms.addAll(symptoms);
    
    _currentStep = 3;
    
    String response = _getLifestyleQuestion(symptoms);
    _addMessage(response, false);
    _speak(response);
  }

  List<String> _extractSymptoms(String text) {
    List<String> symptoms = [];
    String lowerText = text.toLowerCase();
    
    // Symptom mapping for different languages
    Map<String, List<String>> symptomKeywords = {
      'headache': ['headache', 'head pain', 'migraine', 'सिरदर्द', 'தலைவலி', 'తలనొప్పి'],
      'insomnia': ['insomnia', 'sleepless', 'cant sleep', 'नींद न आना', 'தூக்கம் இல்லாமை', 'నిద్రలేమి'],
      'digestion': ['digestion', 'constipation', 'bloating', 'gas', 'पाचन', 'செரிமான', 'జీర్ణక్రియ'],
      'anxiety': ['anxiety', 'stress', 'worry', 'nervous', 'तनाव', 'கவலை', 'ఒత్తిడి'],
      'fatigue': ['fatigue', 'tired', 'exhausted', 'low energy', 'थकान', 'சோர்வு', 'అలసట'],
      'skin': ['skin', 'rash', 'acne', 'dry skin', 'त्वचा', 'தோல்', 'చర్మం']
    };
    
    symptomKeywords.forEach((symptom, keywords) {
      if (keywords.any((keyword) => lowerText.contains(keyword))) {
        symptoms.add(symptom);
      }
    });
    
    return symptoms;
  }

  String _getLifestyleQuestion(List<String> symptoms) {
    String symptomText = symptoms.isNotEmpty ? symptoms.join(', ') : 'these concerns';
    
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'आपके लक्षणों को समझने के लिए, कृपया मुझे अपनी जीवनशैली के बारे में बताएं:\n\n• आपकी भूख कैसी है?\n• आपकी नींद की गुणवत्ता?\n• आपका ऊर्जा स्तर?\n• कोई विशेष आहार?';
      case 'ta-IN':
        return 'உங்கள் அறிகுறிகளைப் புரிந்துகொள்ள, தயவு செய்து உங்கள் வாழ்க்கை முறை பற்றி சொல்லுங்கள்:\n\n• உங்கள் பசி எப்படி இருக்கிறது?\n• உங்கள் தூக்கத்தின் தரம்?\n• உங்கள் ஆற்றல் நிலை?\n• ஏதேனும் சிறப்பு உணவு?';
      case 'te-IN':
        return 'మీ లక్షణాలను అర్థం చేసుకోవడానికి, దయచేసి మీ జీవనశైలి గురించి చెప్పండి:\n\n• మీ ఆకలి ఎలా ఉంది?\n• మీ నిద్ర యొక్క నాణ్యత?\n• మీ శక్తి స్థాయి?\n• ఏదైనా ప్రత్యేక ఆహారం?';
      default:
        return 'To understand your symptoms better, please tell me about your lifestyle:\n\n• How is your appetite?\n• Your sleep quality?\n• Your energy levels?\n• Any specific diet?';
    }
  }

  void _processLifestyle(String text) {
    // Analyze lifestyle and calculate dosha scores
    _analyzeDosha(text);
    _currentStep = 4;
    
    String response = _getDoshaAnalysisResponse();
    _addMessage(response, false);
    _speak(response);
  }

  void _analyzeDosha(String lifestyleText) {
    // Reset scores
    _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
    
    String lowerText = lifestyleText.toLowerCase();
    
    // Vata indicators
    if (lowerText.contains('poor appetite') || lowerText.contains('light sleeper') || 
        lowerText.contains('anxious') || lowerText.contains('dry skin') ||
        lowerText.contains('कम भूख') || lowerText.contains('हल्की नींद') ||
        lowerText.contains('चिंता') || lowerText.contains('रूखी त्वचा')) {
      _doshaScores['vata'] = _doshaScores['vata']! + 40;
    }
    
    // Pitta indicators
    if (lowerText.contains('strong appetite') || lowerText.contains('perfectionist') ||
        lowerText.contains('irritated') || lowerText.contains('acidity') ||
        lowerText.contains('तेज भूख') || lowerText.contains('जलन') ||
        lowerText.contains('एसिडिटी')) {
      _doshaScores['pitta'] = _doshaScores['pitta']! + 40;
    }
    
    // Kapha indicators
    if (lowerText.contains('slow digestion') || lowerText.contains('heavy sleeper') ||
        lowerText.contains('lethargic') || lowerText.contains('weight gain') ||
        lowerText.contains('धीमा पाचन') || lowerText.contains('भारी नींद') ||
        lowerText.contains('सुस्ती')) {
      _doshaScores['kapha'] = _doshaScores['kapha']! + 40;
    }
    
    // Add scores based on symptoms
    for (String symptom in _userSymptoms) {
      switch (symptom) {
        case 'anxiety':
        case 'insomnia':
          _doshaScores['vata'] = _doshaScores['vata']! + 20;
          break;
        case 'headache':
        case 'skin':
          _doshaScores['pitta'] = _doshaScores['pitta']! + 20;
          break;
        case 'fatigue':
          _doshaScores['kapha'] = _doshaScores['kapha']! + 20;
          break;
      }
    }
    
    // Normalize to 100%
    double total = _doshaScores.values.reduce((a, b) => a + b);
    if (total > 0) {
      _doshaScores = _doshaScores.map((key, value) => 
        MapEntry(key, double.parse((value / total * 100).toStringAsFixed(1))));
    }
  }

  String _getDoshaAnalysisResponse() {
    String primaryDosha = _getPrimaryDosha();
    
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'आपकी दोष विश्लेषण तैयार है! 🎯\n\nवात: ${_doshaScores['vata']}%\nपित्त: ${_doshaScores['pitta']}%\nकफ: ${_doshaScores['kapha']}%\n\nआपकी प्रमुख दोष: $primaryDosha\n\nक्या आप इस दोष के लिए आयुर्वेदिक उपचार सुझाव चाहते हैं?';
      case 'ta-IN':
        return 'உங்கள் தோச பகுப்பாய்வு தயார்! 🎯\n\nவாதம்: ${_doshaScores['vata']}%\nபித்தம்: ${_doshaScores['pitta']}%\nகபம்: ${_doshaScores['kapha']}%\n\nஉங்கள் முதன்மை தோச: $primaryDosha\n\nஇந்த தோசத்திற்கான ஆயுர்வேத சிகிச்சை பரிந்துரைகளை விரும்புகிறீர்களா?';
      case 'te-IN':
        return 'మీ దోష విశ్లేషణ సిద్ధంగా ఉంది! 🎯\n\nవాత: ${_doshaScores['vata']}%\nపిత్త: ${_doshaScores['pitta']}%\nకఫ: ${_doshaScores['kapha']}%\n\nమీ ప్రాధమిక దోష: $primaryDosha\n\nమీరు ఈ దోషానికి ఆయుర్వేద చికిత్సా సూచనలు కావాలా?';
      default:
        return 'Your dosha analysis is ready! 🎯\n\nVata: ${_doshaScores['vata']}%\nPitta: ${_doshaScores['pitta']}%\nKapha: ${_doshaScores['kapha']}%\n\nYour primary dosha: $primaryDosha\n\nWould you like Ayurvedic treatment recommendations for this dosha?';
    }
  }

  String _getPrimaryDosha() {
    var sortedEntries = _doshaScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  void _processDoshaAnalysis(String text) {
    bool wantsRemedies = text.toLowerCase().contains('yes') ||
        text.toLowerCase().contains('yeah') ||
        text.toLowerCase().contains('sure') ||
        text.toLowerCase().contains('ok') ||
        text.toLowerCase().contains('हाँ') ||
        text.toLowerCase().contains('हां') ||
        text.toLowerCase().contains('ஆம்') ||
        text.toLowerCase().contains('అవును');

    _currentStep = 5;
    
    String response = wantsRemedies 
        ? _getAyurvedicRemedies()
        : _getGeneralResponse();
    
    _addMessage(response, false);
    _speak(response);
  }

  String _getAyurvedicRemedies() {
    String primaryDosha = _getPrimaryDosha();
    
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'आपकी $primaryDosha दोष के लिए आयुर्वेदिक सुझाव:\n\n🌿 घरेलू नुस्खे:\n${_getHomeRemedies(primaryDosha)}\n\n🍲 आहार सुझाव:\n${_getDietAdvice(primaryDosha)}\n\n🧘‍♀️ जीवनशैली:\n${_getLifestyleAdvice(primaryDosha)}\n\nक्या आप थेरेपी बुक करना चाहेंगे?';
      case 'ta-IN':
        return 'உங்கள் $primaryDosha தோசத்திற்கான ஆயுர்வேத பரிந்துரைகள்:\n\n🌿 வீட்டு வைத்தியம்:\n${_getHomeRemedies(primaryDosha)}\n\n🍲 உணவு ஆலோசனை:\n${_getDietAdvice(primaryDosha)}\n\n🧘‍♀️ வாழ்க்கை முறை:\n${_getLifestyleAdvice(primaryDosha)}\n\nநீங்கள் சிகிச்சை பதிவு செய்ய விரும்புகிறீர்களா?';
      case 'te-IN':
        return 'మీ $primaryDosha దోషానికి ఆయుర్వేద సూచనలు:\n\n🌿 గృహమౌషధాలు:\n${_getHomeRemedies(primaryDosha)}\n\n🍲 ఆహార సలహా:\n${_getDietAdvice(primaryDosha)}\n\n🧘‍♀️ జీవనశైలి:\n${_getLifestyleAdvice(primaryDosha)}\n\nమీరు చికిత్స బుక్ చేయాలనుకుంటున్నారా?';
      default:
        return 'Ayurvedic recommendations for your $primaryDosha dosha:\n\n🌿 Home Remedies:\n${_getHomeRemedies(primaryDosha)}\n\n🍲 Diet Advice:\n${_getDietAdvice(primaryDosha)}\n\n🧘‍♀️ Lifestyle:\n${_getLifestyleAdvice(primaryDosha)}\n\nWould you like to book a therapy session?';
    }
  }

  String _getHomeRemedies(String dosha) {
    switch (dosha) {
      case 'vata':
        return '• Warm milk with nutmeg before bed\n• Ginger tea with honey\n• Daily oil massage\n• Regular warm meals';
      case 'pitta':
        return '• Coconut water daily\n• Aloe vera juice\n• Sandalwood paste for skin\n• Cooling foods';
      case 'kapha':
        return '• Ginger-lemon tea\n• Honey with warm water\n• Dry brushing\n• Spicy foods';
      default:
        return '• Balanced diet and lifestyle';
    }
  }

  String _getDietAdvice(String dosha) {
    switch (dosha) {
      case 'vata':
        return '• Warm, moist, nourishing foods\n• Sweet, sour, salty tastes\n• Avoid cold and dry foods';
      case 'pitta':
        return '• Cooling, refreshing foods\n• Sweet, bitter, astringent tastes\n• Avoid spicy and sour foods';
      case 'kapha':
        return '• Light, warm, dry foods\n• Pungent, bitter, astringent tastes\n• Avoid heavy and oily foods';
      default:
        return '• Balanced diet according to season';
    }
  }

  String _getLifestyleAdvice(String dosha) {
    switch (dosha) {
      case 'vata':
        return '• Regular routine\n• Gentle exercise\n• Adequate rest\n• Warm oil massage';
      case 'pitta':
        return '• Moderate exercise\n• Cooling activities\n• Avoid excessive heat\n• Relaxation techniques';
      case 'kapha':
        return '• Vigorous exercise\n• Active lifestyle\n• Variety in routine\n• Light meals';
      default:
        return '• Balanced daily routine';
    }
  }

  void _processRemedySelection(String text) {
    _currentStep = 6;
    String response = _getFinalMessage();
    _addMessage(response, false);
    _speak(response);
  }

  String _getFinalMessage() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'धन्यवाद $_userName! मुझे आपकी मदद करके खुशी हुई। यदि आपके कोई और प्रश्न हैं या थेरेपी बुक करना चाहते हैं, तो बताएं। आयुर्वेदिक जीवन शैली अपनाएं, स्वस्थ रहें! 🌿';
      case 'ta-IN':
        return 'நன்றி $_userName! உங்களுக்கு உதவியதில் மகிழ்ச்சி. உங்களுக்கு ஏதேனும் கூடுதல் கேள்விகள் இருந்தால் அல்லது சிகிச்சை பதிவு செய்ய விரும்பினால், சொல்லுங்கள். ஆயுர்வேத வாழ்க்கை முறையைப் பின்பற்றுங்கள், ஆரோக்கியமாக இருங்கள்! 🌿';
      case 'te-IN':
        return 'ధన్యవాదాలు $_userName! మీకు సహాయం చేయగలిగినందుకు సంతోషం. మీకు ఇంకా ఏవైనా ప్రశ్నలు ఉంటే లేదా చికిత్స బుక్ చేయాలనుకుంటే, చెప్పండి. ఆయుర్వేద జీవనశైలిని అనుసరించండి, ఆరోగ్యంగా ఉండండి! 🌿';
      default:
        return 'Thank you $_userName! It was a pleasure helping you. If you have any more questions or want to book therapy, let me know. Embrace Ayurvedic lifestyle, stay healthy! 🌿';
    }
  }

  void _processGeneralResponse(String text) {
    String response = _getGeneralResponse();
    _addMessage(response, false);
    _speak(response);
  }

  String _getGeneralResponse() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'मैं आयुर्वेदिक स्वास्थ्य सलाह के लिए यहां हूं $_userName! आप किसी विशेष स्वास्थ्य समस्या के बारे में बात करना चाहते हैं?';
      case 'ta-IN':
        return 'நான் ஆயுர்வேத சுகாதார ஆலோசனைக்காக இங்கு இருக்கிறேன் $_userName! நீங்கள் ஏதேனும் குறிப்பிட்ட சுகாதார பிரச்சினை பற்றி பேச விரும்புகிறீர்களா?';
      case 'te-IN':
        return 'నేను ఆయుర్వేద ఆరోగ్య సలహా కోసం ఇక్కడ ఉన్నాను $_userName! మీరు ఏదైనా ప్రత్యేక ఆరోగ్య సమస్య గురించి మాట్లాడాలనుకుంటున్నారా?';
      default:
        return 'I\'m here for Ayurvedic health advice $_userName! Would you like to talk about any specific health concern?';
    }
  }

  String _extractName(String text) {
    text = text.toLowerCase();
    if (text.contains('my name is')) {
      return text.split('my name is').last.trim();
    } else if (text.contains('i am')) {
      return text.split('i am').last.trim();
    } else if (text.contains('मेरा नाम')) {
      return text.split('मेरा नाम').last.trim();
    } else if (text.contains('मैं')) {
      return text.split('मैं').last.trim();
    } else if (text.contains('என் பெயர்')) {
      return text.split('என் பெயர்').last.trim();
    } else if (text.contains('నా పేరు')) {
      return text.split('నా పేరు').last.trim();
    }
    return text;
  }

  Future<void> _speak(String text) async {
    try {
      String ttsLanguage = _currentLanguage;
      await _flutterTts.setLanguage(ttsLanguage);
      await _flutterTts.speak(text);
    } catch (e) {
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.speak(text);
      } catch (e2) {
        print("Error in TTS fallback: $e2");
      }
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _currentLanguage = _languages[language]!;
    });
    
    _messages.clear();
    _currentStep = 0;
    _userName = '';
    _userSymptoms.clear();
    _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
    _startConversation();
  }

  void _resetConversation() {
    setState(() {
      _messages.clear();
      _currentStep = 0;
      _userName = '';
      _userSymptoms.clear();
      _doshaScores = {'vata': 0, 'pitta': 0, 'kapha': 0};
      _text = '';
    });
    _startConversation();
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Microphone permission is required for speech recognition'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'धन्वंतरी AI 🍃',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) {
              return _languages.keys.map((String language) {
                return PopupMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList();
            },
            icon: Icon(Icons.language, color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetConversation,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Status Indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                        _speechAvailable 
                            ? 'Ready for Ayurvedic consultation'
                            : 'Microphone permission required',
                        style: TextStyle(
                          color: _speechAvailable ? Colors.green : Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Language Indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey[50],
                  child: Text(
                    _getLanguageDisplayText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
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
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Ayurvedic Health Assistant',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Press the microphone to start',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 80,
                          ),
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
                        SizedBox(height: 8),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                
                // Current Speech Text
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
            // FAB positioned absolutely to stay above nav bar
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: AvatarGlow(
                  animate: _isListening,
                  glowColor: _speechAvailable ? Color(0xFF2E7D32) : Colors.orange,
                  duration: Duration(milliseconds: 2000),
                  repeat: true,
                  child: FloatingActionButton(
                    onPressed: _listen,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 30,
                    ),
                    backgroundColor: _isListening 
                        ? Colors.red 
                        : (_speechAvailable ? Color(0xFF2E7D32) : Colors.orange),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayText() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'Language: Hindi - आयुर्वेदिक सहायक';
      case 'ta-IN':
        return 'Language: Tamil - ஆயுர்வேத உதவியாளர்';
      case 'te-IN':
        return 'Language: Telugu - ఆయుర్వేద సహాయకుడు';
      default:
        return 'Language: English - Ayurvedic Assistant';
    }
  }

  @override
  void dispose() {
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
                backgroundColor: Colors.transparent,
                backgroundImage: NetworkImage('https://img.freepik.com/premium-vector/ayurveda-doctor-character-illustration_2175-5125.jpg'),
                radius: 16,
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF2E7D32) : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: isUser ? null : Border.all(color: Colors.green[100]!),
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