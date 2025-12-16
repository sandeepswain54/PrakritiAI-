// updated_remedy_service.dart
import 'dart:convert';


import 'package:service_app/CSV_Ayurveda_Dataset/ayurveda_data_service.dart' show AyurvedaDataService;

class RemedyService {
  static bool _isDataInitialized = false;

  // Initialize with CSV data
  static Future<void> initializeWithCSV(String csvData) async {
    if (_isDataInitialized) return;
    
    AyurvedaDataService.initializeData(csvData);
    _isDataInitialized = true;
    print('✅ Ayurvedic dataset loaded: ${AyurvedaDataService.getAllDiseases().length} diseases');
  }

  // Enhanced symptom extraction using CSV data
  static Future<List<String>> extractSymptoms(String query) async {
    String lowerQuery = query.toLowerCase();
    List<String> detectedDiseases = [];

    // Find diseases matching the query
    var diseases = AyurvedaDataService.findDiseasesByQuery(lowerQuery);
    for (var disease in diseases) {
      String diseaseName = disease['Disease']?.toString() ?? '';
      if (diseaseName.isNotEmpty && !detectedDiseases.contains(diseaseName)) {
        detectedDiseases.add(diseaseName);
      }
    }

    // If no diseases found, try keyword matching
    if (detectedDiseases.isEmpty) {
      Map<String, List<String>> symptomKeywords = {
        'Cough': ['खांसी', 'खोकला', 'cough', 'sore throat', 'chest congestion', 'कफ', 'गले', 'throat'],
        'Diabetes': ['मधुमेह', 'diabetes', 'frequent urination', 'fatigue', 'प्यास', 'थकान', 'शुगर', 'sugar'],
        'Hypertension': ['उच्च रक्तचाप', 'high blood pressure', 'bp', 'बीपी', 'रक्तचाप', 'blood pressure'],
        'Migraine': ['माइग्रेन', 'migraine', 'सिरदर्द', 'headache', 'आधा सिर दर्द', 'सर दर्द'],
        'Arthritis': ['गठिया', 'arthritis', 'joint pain', 'जोड़ों का दर्द', 'सूजन', 'जोड़'],
        'Common Cold': ['सर्दी', 'cold', 'जुकाम', 'runny nose', 'sneezing', 'ठंड', 'नाक बहना'],
        'Indigestion': ['पाचन समस्या', 'indigestion', 'bloating', 'गैस', 'अपच', 'पेट', 'stomach'],
        'Asthma': ['दमा', 'asthma', 'सांस', 'wheezing', 'श्वास', 'breathing', 'साँस'],
        'Constipation': ['कब्ज', 'constipation', 'बद्धकोष्ठता', 'hard stools', 'पेट साफ'],
        'Fever': ['बुखार', 'fever', 'ताप', 'temperature', 'ज्वर', 'बुखार'],
        'Acidity': ['अम्लपित्त', 'acidity', 'एसिडिटी', 'heartburn', 'छाती जलन', 'सीने जलन'],
        'Skin Allergy': ['त्वचा एलर्जी', 'skin allergy', 'खुजली', 'रैश', 'rash', 'चकत्ते'],
        'Anxiety': ['चिंता', 'anxiety', 'तनाव', 'stress', 'घबराहट', 'nervousness'],
        'Back Pain': ['पीठ दर्द', 'back pain', 'कमर दर्द', 'पीठ', 'कमर'],
        'Insomnia': ['अनिद्रा', 'insomnia', 'नींद', 'sleep', 'सोना', 'निद्रा'],
      };

      symptomKeywords.forEach((disease, keywords) {
        if (keywords.any((keyword) => lowerQuery.contains(keyword.toLowerCase()))) {
          if (!detectedDiseases.contains(disease)) {
            detectedDiseases.add(disease);
          }
        }
      });
    }

    // Limit to 2 most relevant diseases
    if (detectedDiseases.length > 2) {
      detectedDiseases = detectedDiseases.sublist(0, 2);
    }

    print('🔍 Detected health issues: $detectedDiseases for query: "$query"');
    return detectedDiseases;
  }

  // Get comprehensive Ayurvedic recommendations from CSV
  static Future<List<Map<String, dynamic>>> getRemediesForSymptoms(List<String> diseases) async {
    List<Map<String, dynamic>> remedies = [];
    
    for (String diseaseName in diseases) {
      var disease = AyurvedaDataService.getDiseaseByName(diseaseName);
      if (disease != null) {
        remedies.add(_formatDiseaseAsRemedy(disease));
      }
    }

    // If no diseases found in CSV, provide general advice
    if (remedies.isEmpty) {
      remedies.add(_getGeneralAdvice());
    }

    return remedies;
  }

  // Format disease data as remedy
  static Map<String, dynamic> _formatDiseaseAsRemedy(Map<String, dynamic> disease) {
    return {
      'disease': disease['Disease'] ?? 'Unknown',
      'hindiName': disease['Hindi Name'] ?? '',
      'marathiName': disease['Marathi Name'] ?? '',
      'symptoms': disease['Symptoms'] ?? '',
      'doshas': disease['Doshas'] ?? '',
      'prakriti': disease['Constitution/Prakriti'] ?? '',
      'ayurvedicHerbs': disease['Ayurvedic Herbs'] ?? '',
      'formulation': disease['Formulation'] ?? '',
      'dietRecommendations': disease['Diet and Lifestyle Recommendations'] ?? '',
      'yogaTherapy': disease['Yoga & Physical Therapy'] ?? '',
      'prevention': disease['Prevention'] ?? '',
      'patientRecommendations': disease['Patient Recommendations'] ?? '',
      'remedy': 'आयुर्वेदिक उपचार',
      'ingredients': _extractIngredients(disease['Ayurvedic Herbs']?.toString() ?? ''),
      'preparation': _simplifyPreparation(disease['Formulation']?.toString() ?? ''),
      'usage': _simplifyUsage(disease['Patient Recommendations']?.toString() ?? ''),
      'benefits': 'प्राकृतिक रूप से रोग नियंत्रण',
      'warnings': 'गंभीर स्थिति में चिकित्सक से परामर्श लें',
      'source': 'आयुर्वेदिक डेटाबेस',
      'effectiveness': '८५%',
      'preparation_time': 'विधि के अनुसार'
    };
  }

  static List<String> _extractIngredients(String herbsText) {
    List<String> ingredients = [];
    List<String> commonHerbs = ['तुलसी', 'अदरक', 'हल्दी', 'अश्वगंधा', 'गिलोय', 'त्रिफला', 'नीम', 'आंवला'];
    
    for (String herb in commonHerbs) {
      if (herbsText.contains(herb)) {
        ingredients.add(herb);
      }
    }
    
    return ingredients.isNotEmpty ? ingredients : ['प्राकृतिक जड़ी बूटियाँ'];
  }

  static String _simplifyPreparation(String formulation) {
    if (formulation.length > 100) {
      return formulation.substring(0, 100) + '...';
    }
    return formulation.isEmpty ? 'आयुर्वेदिक विधि से तैयार' : formulation;
  }

  static String _simplifyUsage(String recommendations) {
    if (recommendations.length > 80) {
      return recommendations.substring(0, 80) + '...';
    }
    return recommendations.isEmpty ? 'नियमित रूप से उपयोग करें' : recommendations;
  }

  static Map<String, dynamic> _getGeneralAdvice() {
    return {
      'remedy': 'सामान्य स्वास्थ्य सलाह',
      'ingredients': ['ताजा भोजन', 'शुद्ध पानी', 'योग', 'ध्यान'],
      'preparation': 'संतुलित आहार और नियमित व्यायाम',
      'usage': 'दैनिक जीवन में अपनाएं',
      'benefits': 'स्वस्थ जीवनशैली',
      'warnings': 'लगातार समस्या होने पर डॉक्टर से मिलें',
      'source': 'पारंपरिक ज्ञान',
      'effectiveness': '९०%',
      'preparation_time': 'नियमित'
    };
  }

  // Generate friendly grandmother-style response
  static String generateFriendlyResponse(List<Map<String, dynamic>> remedies, String userQuery) {
    if (remedies.isEmpty) {
      return 'बेटा, इस समस्या के लिए मेरे पास कोई नुस्खा नहीं है। कृपया डॉक्टर से सलाह लें। 💚';
    }

    String response = 'अरे बेटा! तुम्हारी परेशानी सुनकर मुझे आयुर्वेदिक उपचार याद आए:\n\n';

    for (int i = 0; i < remedies.length; i++) {
      var remedy = remedies[i];
      
      response += '🌿 **${remedy['hindiName']} (${remedy['disease']})**\n\n';
      
      if (remedy['symptoms'].toString().isNotEmpty) {
        response += '**लक्षण:** ${remedy['symptoms']}\n';
      }
      
      if (remedy['doshas'].toString().isNotEmpty) {
        response += '**दोष:** ${remedy['doshas']}\n';
      }
      
      if (remedy['ayurvedicHerbs'].toString().isNotEmpty) {
        response += '**आयुर्वेदिक जड़ी-बूटियाँ:** ${remedy['ayurvedicHerbs']}\n';
      }
      
      if (remedy['formulation'].toString().isNotEmpty) {
        response += '**उपचार विधि:** ${remedy['formulation']}\n';
      }
      
      if (remedy['dietRecommendations'].toString().isNotEmpty) {
        response += '**आहार सलाह:** ${remedy['dietRecommendations']}\n';
      }
      
      if (remedy['yogaTherapy'].toString().isNotEmpty) {
        response += '**योग:** ${remedy['yogaTherapy']}\n';
      }
      
      response += '\n';
    }

    response += '💚 याद रखना बेटा, प्रकृति का उपचार धीरे काम करता है। नियमित रूप से करो और २-३ दिन में आराम न मिले तो डॉक्टर को जरूर दिखाएं!';

    return response;
  }
}