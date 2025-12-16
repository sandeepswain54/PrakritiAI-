class TwilioConfig {
  static const String accountSid = String.fromEnvironment('TWILIO_ACCOUNT_SID');
  static const String authToken = String.fromEnvironment('TWILIO_AUTH_TOKEN');
  static const String whatsAppFrom = String.fromEnvironment('TWILIO_WHATSAPP_FROM');
  static const String yourWhatsAppNumber = String.fromEnvironment('YOUR_WHATSAPP_NUMBER');
  
  static bool get isConfigured {
    return accountSid.isNotEmpty && 
           authToken.isNotEmpty && 
           whatsAppFrom.isNotEmpty && 
           yourWhatsAppNumber.isNotEmpty;
  }
}