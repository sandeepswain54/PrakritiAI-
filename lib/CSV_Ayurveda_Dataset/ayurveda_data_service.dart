// ayurveda_data_service.dart
import 'dart:convert';

class AyurvedaDataService {
  static List<Map<String, dynamic>> _diseaseData = [];

  // Parse CSV data
  static void initializeData(String csvData) {
    try {
      List<String> lines = LineSplitter().convert(csvData);
      if (lines.isEmpty) return;

      // Get headers - handle the BOM character if present
      List<String> headers = lines[0].replaceAll('\uFEFF', '').split(',').map((e) => e.trim()).toList();
      
      // Parse each row
      _diseaseData = lines.sublist(1).where((line) => line.trim().isNotEmpty).map((line) {
        List<String> values = _parseCSVLine(line);
        Map<String, dynamic> disease = {};
        
        for (int i = 0; i < headers.length && i < values.length; i++) {
          disease[headers[i]] = values[i].trim();
        }
        return disease;
      }).toList();

      print('✅ Loaded ${_diseaseData.length} diseases from CSV');
    } catch (e) {
      print('❌ Error parsing CSV: $e');
    }
  }

  // Helper method to parse CSV line considering quotes
  static List<String> _parseCSVLine(String line) {
    List<String> result = [];
    String current = '';
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current);
    return result;
  }

  // Find diseases by symptoms or disease name
  static List<Map<String, dynamic>> findDiseasesByQuery(String query) {
    if (_diseaseData.isEmpty) return [];
    
    String lowerQuery = query.toLowerCase();
    
    return _diseaseData.where((disease) {
      String symptoms = disease['Symptoms']?.toString().toLowerCase() ?? '';
      String diseaseName = disease['Disease']?.toString().toLowerCase() ?? '';
      String hindiName = disease['Hindi Name']?.toString().toLowerCase() ?? '';
      String marathiName = disease['Marathi Name']?.toString().toLowerCase() ?? '';
      
      return symptoms.contains(lowerQuery) || 
             diseaseName.contains(lowerQuery) ||
             hindiName.contains(lowerQuery) ||
             marathiName.contains(lowerQuery) ||
             _checkPartialMatch(symptoms, lowerQuery) ||
             _checkPartialMatch(diseaseName, lowerQuery);
    }).toList();
  }

  static bool _checkPartialMatch(String text, String query) {
    List<String> queryWords = query.split(' ');
    return queryWords.any((word) => word.length > 2 && text.contains(word));
  }

  // Get all available diseases
  static List<String> getAllDiseases() {
    return _diseaseData.map((disease) => disease['Disease']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
  }

  // Get disease by exact name
  static Map<String, dynamic>? getDiseaseByName(String name) {
    try {
      return _diseaseData.firstWhere(
        (disease) => disease['Disease']?.toString().toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}