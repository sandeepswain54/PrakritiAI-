// services/tongue_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';

class TongueApiService {
  // Use your specific IP address
  static const String baseUrl = 'http://192.168.23.64:5000';
  
  Future<Either<String, Map<String, dynamic>>> analyzeTongueImage(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      print('Sending request to: $baseUrl/predict');
      print('Image path: ${imageFile.path}');
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Right(data);
      } else {
        return Left('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in API call: $e');
      return Left('Network error: $e');
    }
  }

  Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Connection': 'keep-alive'},
      ).timeout(Duration(seconds: 10));
      
      print('Server health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Server connection check failed: $e');
      return false;
    }
  }

  // Method to test different endpoints
  Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      print('Root endpoint: ${response.statusCode}');
    } catch (e) {
      print('Root endpoint test failed: $e');
    }
  }
}