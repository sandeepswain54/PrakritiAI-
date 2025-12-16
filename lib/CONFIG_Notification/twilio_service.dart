import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TwilioService {
  // ⚠️ SECURITY: Credentials should be loaded from environment variables or backend
  // DO NOT hardcode sensitive credentials in source code
  // Use flutter_dotenv to load from .env file (add .env to .gitignore)
  
  static late String accountSid;
  static late String authToken;
  static const String fromNumber = 'whatsapp:+14155238886'; // Twilio sandbox number
  static late String toNumber;

  static Future<bool> sendWhatsAppMessage({
    required String serviceName,
    required String orderID,
    required int nights,
    required List<DateTime> selectedDates,
    required double totalAmount,
    required String customerName,
  }) async {
    try {
      debugPrint('🔧 Starting Twilio WhatsApp send...');
      debugPrint('📞 To: $toNumber');
      debugPrint('📞 From: $fromNumber');

      // Format dates for better readability
      final formattedDates = selectedDates.map((date) => 
          "${date.day}/${date.month}/${date.year}").join(", ");

      final String messageBody = 
          '📅 *NEW BOOKING ALERT!* 🎉\n\n'
          '🏷️ *Service:* $serviceName\n'
          '📋 *Order ID:* $orderID\n'
          '🛏️ *Nights:* $nights\n'
          '📅 *Dates:* $formattedDates\n'
          '💰 *Total Amount:* \$${totalAmount.toStringAsFixed(2)}\n'
          '👤 *Customer:* $customerName\n'
          '⏰ *Booking Time:* ${DateTime.now().toString().split('.')[0]}\n\n'
          '✅ *Please confirm this booking.*';

      debugPrint('💬 Message Length: ${messageBody.length}');

      final Uri url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
      );

      debugPrint('🌐 Sending request to Twilio API...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ' + 
            base64Encode(utf8.encode('$accountSid:$authToken')),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromNumber,
          'To': toNumber,
          'Body': messageBody,
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Response Status Code: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        debugPrint('✅ WhatsApp message sent successfully via Twilio');
        return true;
      } else {
        debugPrint('❌ Failed to send WhatsApp message: ${response.statusCode}');
        if (response.statusCode == 400) {
          debugPrint('❌ Bad Request - Check phone number format');
        } else if (response.statusCode == 401) {
          debugPrint('❌ Unauthorized - Check Account SID and Auth Token');
        } else if (response.statusCode == 404) {
          debugPrint('❌ Not Found - Check Twilio number');
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending WhatsApp message: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Test method to verify Twilio setup
  static Future<bool> testTwilioConnection() async {
    try {
      debugPrint('🧪 Testing Twilio connection...');
      
      final Uri url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ' + 
            base64Encode(utf8.encode('$accountSid:$authToken')),
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('🧪 Twilio test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🧪 Twilio test failed: $e');
      return false;
    }
  }
}