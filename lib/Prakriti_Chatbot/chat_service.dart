import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TogetherAIService {
  static const String _baseUrl = 'https://api.together.xyz/v1';
  static const String _defaultModel = 'mistralai/Mixtral-8x7B-Instruct-v0.1';

  Future<String> generateResponse(String prompt) async {
    final apiKey = dotenv.env['TOGETHER_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key not configured in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'), // Note: Changed endpoint
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 30));

      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return responseBody['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception(
          'API Error (${response.statusCode}): ${responseBody['error']?['message'] ?? response.body}'
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again');
    } catch (e) {
      throw Exception('Failed to generate response: ${e.toString()}');
    }
  }
}