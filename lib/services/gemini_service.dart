import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
 
  final String apiKey = "AIzaSyAr2AaFZoIsawsDoqWxoioJAAUHjnBUaSM"; 

  Future<Map<String, dynamic>> analyzeEmergency(String userInput) async {
    final url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are an emergency AI. Analyze: "$userInput"
Classify into: accident, fire, crime, or general_emergency.
Return ONLY JSON:
{"type": "type_here", "isDanger": true/false, "alert": "Short alert message"}
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];

        // JSON extraction logic
        final jsonStart = rawText.indexOf("{");
        final jsonEnd = rawText.lastIndexOf("}") + 1;
        String jsonString = rawText.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonString);
      } else {
        return _fallbackResponse(userInput);
      }
    } catch (e) {
      return _fallbackResponse(userInput);
    }
  }

  
  Future<bool> checkDanger(String text) async {
    final result = await analyzeEmergency(text);
    return result["isDanger"] ?? false;
  }

  Map<String, dynamic> _fallbackResponse(String input) {
   
    return {
      "type": "general_emergency",
      "isDanger": true,
      "alert": "Emergency detected via fallback logic."
    };
  }
}