import 'package:shared_preferences/shared_preferences.dart';

/// AI Service Configuration
/// 
/// Users can configure their own Gemini API key in Settings > AI Configuration
/// Free API key available at: https://aistudio.google.com/app/apikey
class AIConfig {
  static const String _apiKeyPref = 'gemini_api_key';
  
  // Default API key (users must provide their own in app settings)
  // Get your free key at: https://aistudio.google.com/app/apikey
  static const String _defaultApiKey = '';
  
  /// Get the current API key (user's custom key or default)
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref) ?? _defaultApiKey;
  }
  
  /// Save user's custom API key
  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
  }
  
  /// Clear custom API key (revert to default)
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
  }
  
  /// Check if AI is enabled
  static Future<bool> isEnabled() async {
    final key = await getApiKey();
    return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY_HERE';
  }
  
  /// Check if using custom (user-provided) key
  static Future<bool> isUsingCustomKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_apiKeyPref);
  }
}
