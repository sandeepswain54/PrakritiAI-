import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'chat_service.dart';


class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
class ChatProvider with ChangeNotifier {
  final TogetherAIService _aiService;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastError;
  bool _isConnected = true;

  ChatProvider(this._aiService) {
    _initConnectivity();
  }

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConnected => _isConnected;

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

    Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    debugPrint('Sending message: $message');
    
    _addMessage(message, true);
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isConnected) {
        throw Exception('No internet connection');
      }

      final response = await _aiService.generateResponse(message);
      debugPrint('Received response: $response');
      _addMessage(response, false);
    } catch (e) {
      debugPrint('Error details: $e');
      _lastError = e.toString();
      _addMessage(_getErrorMessage(e), false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(dynamic error) {
  final message = error.toString();
  
  if (message.contains('No internet')) {
    return 'Please check your internet connection';
  } else if (message.contains('timed out')) {
    return 'The request took too long. Please try again';
  } else if (message.contains('API key') || message.contains('401')) {
    return 'API authentication failed. Please check your configuration';
  } else if (message.contains('500')) {
    return 'Server error. Please try again later';
  } else if (message.contains('model')) {
    return 'Model configuration error';
  }
  
  return 'Error: ${message.split(':').last.trim()}'; // More specific error
}

  void _addMessage(String text, bool isUser) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    ));
    _lastError = null;
    notifyListeners();
  }
}