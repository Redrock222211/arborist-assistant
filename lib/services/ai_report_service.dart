import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site.dart';
import '../models/tree_entry.dart';
import '../models/report_type.dart';

/// AI provider options
enum AIProvider {
  openai,
  anthropic,
  google,
}

extension AIProviderExtension on AIProvider {
  String get name {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI (GPT-4o-mini)';
      case AIProvider.anthropic:
        return 'Anthropic (Claude 3.5 Haiku)';
      case AIProvider.google:
        return 'Google (Gemini 1.5 Flash)';
    }
  }
  
  String get code {
    switch (this) {
      case AIProvider.openai:
        return 'openai';
      case AIProvider.anthropic:
        return 'anthropic';
      case AIProvider.google:
        return 'google';
    }
  }
}

AIProvider aiProviderFromCode(String code) {
  switch (code.toLowerCase()) {
    case 'anthropic':
      return AIProvider.anthropic;
    case 'google':
      return AIProvider.google;
    default:
      return AIProvider.openai;
  }
}

/// AI-powered report text generation using multiple providers
class AIReportService {
  static const String _apiKeyPref = 'ai_api_key';
  static const String _aiEnabledPref = 'ai_enabled';
  static const String _aiProviderPref = 'ai_provider';
  
  /// Get the API key
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }
  
  /// Legacy method for backwards compatibility
  static Future<String?> getOpenAIKey() => getApiKey();
  
  /// Set the API key
  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
  }
  
  /// Legacy method for backwards compatibility
  static Future<void> setOpenAIKey(String apiKey) => setApiKey(apiKey);
  
  /// Get the selected AI provider
  static Future<AIProvider> getProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_aiProviderPref) ?? 'openai';
    return aiProviderFromCode(code);
  }
  
  /// Set the AI provider
  static Future<void> setProvider(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiProviderPref, provider.code);
  }
  
  /// Check if AI is enabled
  static Future<bool> isAIEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_aiEnabledPref) ?? false;
    final key = await getApiKey();
    return enabled && key != null && key.isNotEmpty;
  }
  
  /// Legacy method for backwards compatibility
  static Future<bool> isOpenAIEnabled() => isAIEnabled();
  
  /// Toggle AI enabled status
  static Future<void> setAIEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledPref, enabled);
  }
  
  /// Legacy method for backwards compatibility  
  static Future<void> setOpenAIEnabled(bool enabled) => setAIEnabled(enabled);
  
  /// Generate AI-powered report sections
  static Future<Map<String, String>> generateReportSections({
    required Site site,
    required List<TreeEntry> trees,
    required ReportType reportType,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('AI API key not configured');
    }
    
    final provider = await getProvider();
    print('🤖 Generating AI report sections using ${provider.name}...');
    
    try {
      // Prepare context data
      final context = _prepareContext(site, trees, reportType);
      
      // Generate different sections based on provider
      final introduction = await _generateSection(
        apiKey,
        provider,
        'introduction',
        context,
        reportType,
      );
      
      final discussion = await _generateSection(
        apiKey,
        provider,
        'discussion',
        context,
        reportType,
      );
      
      final conclusions = await _generateSection(
        apiKey,
        provider,
        'conclusions',
        context,
        reportType,
      );
      
      final recommendations = await _generateSection(
        apiKey,
        provider,
        'recommendations',
        context,
        reportType,
      );
      
      print('✅ AI report sections generated');
      
      return Map<String, String>.from({
        'ai_introduction': introduction,
        'ai_discussion': discussion,
        'ai_conclusions': conclusions,
        'ai_recommendations': recommendations,
      });
    } catch (e) {
      print('❌ Error generating AI sections: $e');
      rethrow;
    }
  }
  
  /// Prepare context for AI generation
  static String _prepareContext(Site site, List<TreeEntry> trees, ReportType reportType) {
    final buffer = StringBuffer();
    
    buffer.writeln('Site: ${site.name}');
    buffer.writeln('Address: ${site.address}');
    buffer.writeln('Report Type: ${reportType.title} (${reportType.code})');
    buffer.writeln('\nTree Summary:');
    buffer.writeln('Total Trees: ${trees.length}');
    
    // Risk distribution
    final highRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('high')).length;
    final mediumRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('medium') || 
                                           t.overallRiskRating.toLowerCase().contains('moderate')).length;
    final lowRisk = trees.where((t) => t.overallRiskRating.toLowerCase().contains('low')).length;
    
    buffer.writeln('High Risk: $highRisk');
    buffer.writeln('Medium Risk: $mediumRisk');
    buffer.writeln('Low Risk: $lowRisk');
    
    // Condition distribution
    final poor = trees.where((t) => t.condition.toLowerCase() == 'poor' || t.condition.toLowerCase() == 'critical').length;
    final fair = trees.where((t) => t.condition.toLowerCase() == 'fair').length;
    final good = trees.where((t) => t.condition.toLowerCase() == 'good').length;
    
    buffer.writeln('\nCondition Summary:');
    buffer.writeln('Good: $good, Fair: $fair, Poor/Critical: $poor');
    
    // Species diversity
    final speciesMap = <String, int>{};
    for (final tree in trees) {
      speciesMap[tree.species] = (speciesMap[tree.species] ?? 0) + 1;
    }
    
    buffer.writeln('\nSpecies:');
    speciesMap.forEach((species, count) {
      buffer.writeln('- $species: $count trees');
    });
    
    // Permits
    final permitsRequired = trees.where((t) => t.permitRequired).length;
    if (permitsRequired > 0) {
      buffer.writeln('\nPermits Required: $permitsRequired trees');
    }
    
    return buffer.toString();
  }
  
  /// Generate a specific section using the selected AI provider
  static Future<String> _generateSection(
    String apiKey,
    AIProvider provider,
    String sectionType,
    String context,
    ReportType reportType,
  ) async {
    final prompt = _buildPrompt(sectionType, context, reportType);
    
    print('🤖 Generating $sectionType section...');
    
    switch (provider) {
      case AIProvider.openai:
        return _generateWithOpenAI(apiKey, prompt, sectionType);
      case AIProvider.anthropic:
        return _generateWithAnthropic(apiKey, prompt, sectionType);
      case AIProvider.google:
        return _generateWithGoogle(apiKey, prompt, sectionType);
    }
  }
  
  /// Generate using OpenAI
  static Future<String> _generateWithOpenAI(String apiKey, String prompt, String sectionType) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert arborist writing professional arboricultural reports. Write in a formal, technical style suitable for planning authorities and legal proceedings.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 800,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      print('✅ $sectionType generated (${text.length} characters)');
      return text.trim();
    } else {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Generate using Anthropic Claude
  static Future<String> _generateWithAnthropic(String apiKey, String prompt, String sectionType) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-5-haiku-20241022',
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': 'You are an expert arborist writing professional arboricultural reports. Write in a formal, technical style suitable for planning authorities and legal proceedings.\n\n$prompt',
          },
        ],
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      print('✅ $sectionType generated (${text.length} characters)');
      return text.trim();
    } else {
      throw Exception('Anthropic API error: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Generate using Google Gemini
  static Future<String> _generateWithGoogle(String apiKey, String prompt, String sectionType) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'You are an expert arborist writing professional arboricultural reports. Write in a formal, technical style suitable for planning authorities and legal proceedings.\n\n$prompt'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
        },
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      print('✅ $sectionType generated (${text.length} characters)');
      return text.trim();
    } else {
      throw Exception('Google API error: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Build prompt for specific section
  static String _buildPrompt(String sectionType, String context, ReportType reportType) {
    final basePrompt = 'Based on the following tree assessment data, write a professional $sectionType section for a ${reportType.title}:\n\n$context\n\n';
    
    switch (sectionType) {
      case 'introduction':
        return '${basePrompt}Write a brief introduction (2-3 paragraphs) that:\n'
               '- States the purpose of the report\n'
               '- Describes the site location and context\n'
               '- Outlines the scope of the assessment\n'
               '- Mentions the total number of trees assessed and key species present';
      
      case 'discussion':
        return '${basePrompt}Write a detailed discussion section (3-4 paragraphs) that:\n'
               '- Analyzes the overall tree population health and condition\n'
               '- Discusses risk distribution and any high-risk trees requiring urgent attention\n'
               '- Examines species diversity and site characteristics\n'
               '- Addresses any permit requirements or regulatory considerations\n'
               '- Discusses retention values and ecological significance';
      
      case 'conclusions':
        return '${basePrompt}Write a conclusions section (2-3 paragraphs) that:\n'
               '- Summarizes the key findings of the assessment\n'
               '- States the overall condition of the tree population\n'
               '- Highlights critical issues or concerns\n'
               '- Confirms compliance or non-compliance with relevant standards';
      
      case 'recommendations':
        return '${basePrompt}Write a recommendations section (numbered list format) that provides:\n'
               '- Specific actionable recommendations for tree management\n'
               '- Priority actions for high-risk or poor condition trees\n'
               '- Tree protection measures if development is proposed\n'
               '- Ongoing monitoring and maintenance requirements\n'
               '- Permit application requirements if applicable\n'
               'Format as a numbered list with clear, specific recommendations.';
      
      default:
        return basePrompt;
    }
  }
}
