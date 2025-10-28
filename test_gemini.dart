import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  final apiKey = 'AIzaSyAs0bNETFCPJJADZd6M5h0q6ieAFPRtGLc';
  
  print('Testing Gemini API - Listing available models...');
  
  // Try to call the list models endpoint directly
  try {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey')
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('\n=== Available Models ===');
    print(responseBody);
    httpClient.close();
  } catch (e) {
    print('Error listing models: $e');
  }
  
  print('\n--- Now trying gemini-2.0-flash-exp ---');
  try {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
    );
    
    final response = await model.generateContent([
      Content.text('Generate LGA local laws for WHITTLESEA council tree removal. Include: Local Law number, tree size thresholds, permit fees, exemptions. Be specific.')
    ]).timeout(Duration(seconds: 15));
    
    print('✅ SUCCESS!');
    print('Response: ${response.text}');
  } catch (e) {
    print('❌ FAILED: $e');
  }
}
