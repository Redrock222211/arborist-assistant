import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';

/// AI-powered planning permit summary service
/// Uses Google Gemini to interpret Victorian planning overlays and generate accurate permit summaries
class PlanningAIService {
  static GenerativeModel? _model;
  
  /// Initialize the AI model
  static Future<void> initialize() async {
    final key = await AIConfig.getApiKey();
    final enabled = await AIConfig.isEnabled();
    
    if (!enabled) {
      print('⚠️ PlanningAIService: No API key configured. Using fallback summaries.');
      print('   Add your Gemini API key in Settings > AI Configuration to enable AI summaries.');
      return;
    }
    
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',  // Working Gemini 2.0 Flash model (verified from API)
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Lower temperature for more factual responses
        maxOutputTokens: 1000,
      ),
    );
    
    final isCustom = await AIConfig.isUsingCustomKey();
    print('✅ PlanningAIService: Initialized with ${isCustom ? "custom" : "default"} API key');
  }
  
  /// Generate permit summary from overlay data
  static Future<String> generatePermitSummary({
    required String lga,
    required List<Map<String, dynamic>> overlays,
    required List<Map<String, dynamic>> zones,
  }) async {
    if (_model == null) {
      return _generateFallbackSummary(lga, overlays, zones);
    }
    
    try {
      final prompt = _buildPrompt(lga, overlays, zones);
      print('🤖 Generating AI permit summary for $lga...');
      
      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));
      
      final summary = response.text ?? '';
      if (summary.isEmpty) {
        return _generateFallbackSummary(lga, overlays, zones);
      }
      
      print('✅ AI summary generated successfully');
      return summary + '\n\n⚠️ AI-generated summary (April 2024 data). Verify with council.';
    } catch (e) {
      print('⚠️ AI summary failed: $e. Using fallback.');
      return _generateFallbackSummary(lga, overlays, zones);
    }
  }
  
  /// Build prompt for AI
  static String _buildPrompt(
    String lga,
    List<Map<String, dynamic>> overlays,
    List<Map<String, dynamic>> zones,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert Victorian arborist and planning consultant.');
    buffer.writeln('');
    buffer.writeln('TASK: Generate a clear, accurate tree permit summary for a property based on planning data.');
    buffer.writeln('');
    buffer.writeln('LOCATION:');
    buffer.writeln('LGA: $lga');
    buffer.writeln('');
    
    if (overlays.isNotEmpty) {
      buffer.writeln('PLANNING OVERLAYS:');
      for (final overlay in overlays) {
        final code = overlay['overlay'] ?? overlay['ZONE_CODE'] ?? '';
        final desc = overlay['description'] ?? overlay['ZONE_DESCRIPTION'] ?? '';
        buffer.writeln('- $code: $desc');
      }
      buffer.writeln('');
    }
    
    if (zones.isNotEmpty) {
      buffer.writeln('PLANNING ZONES:');
      for (final zone in zones) {
        final code = zone['zone'] ?? zone['ZONE_CODE'] ?? '';
        final desc = zone['description'] ?? zone['ZONE_DESCRIPTION'] ?? '';
        buffer.writeln('- $code: $desc');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('REQUIREMENTS:');
    buffer.writeln('1. For EACH overlay/zone, provide specific tree permit requirements');
    buffer.writeln('2. Include EXACT measurements (DBH, height, canopy size, trunk circumference)');
    buffer.writeln('3. Specify what requires a permit (removal, pruning, lopping)');
    buffer.writeln('4. List exemptions (dead/dying trees, emergency works, etc.)');
    buffer.writeln('5. Include Amendment VC289 (Clause 52.37) canopy tree protection if applicable');
    buffer.writeln('6. Keep the summary concise but complete');
    buffer.writeln('');
    buffer.writeln('FORMAT: Use bullet points. Start with overlay/zone code, then requirements.');
    buffer.writeln('Example: "VPO2: Permit required to remove trees DBH > 20cm or prune limbs > 10cm diameter"');
    
    return buffer.toString();
  }
  
  /// Fallback summary when AI is unavailable
  static String _generateFallbackSummary(
    String lga,
    List<Map<String, dynamic>> overlays,
    List<Map<String, dynamic>> zones,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('📍 LGA: $lga');
    buffer.writeln('');
    
    if (overlays.isNotEmpty) {
      buffer.writeln('📋 PLANNING OVERLAYS DETECTED:');
      for (final overlay in overlays) {
        final code = overlay['overlay'] ?? overlay['ZONE_CODE'] ?? 'Unknown';
        final desc = overlay['description'] ?? overlay['ZONE_DESCRIPTION'] ?? '';
        buffer.writeln('• $code: $desc');
        buffer.writeln('  → Contact council for specific permit requirements');
      }
      buffer.writeln('');
    }
    
    if (zones.isNotEmpty) {
      buffer.writeln('🏘️ PLANNING ZONES:');
      for (final zone in zones) {
        final code = zone['zone'] ?? zone['ZONE_CODE'] ?? 'Unknown';
        final desc = zone['description'] ?? zone['ZONE_DESCRIPTION'] ?? '';
        buffer.writeln('• $code: $desc');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('⚠️ IMPORTANT:');
    buffer.writeln('AI summary unavailable. Contact $lga council for:');
    buffer.writeln('• Specific permit thresholds for these overlays/zones');
    buffer.writeln('• Application requirements and fees');
    buffer.writeln('• Processing times');
    
    return buffer.toString();
  }
  
  /// Generate LGA-specific local laws summary using AI
  static Future<String> generateLGALocalLaws({
    required String lga,
  }) async {
    if (_model == null) {
      print('⚠️ PlanningAIService: Model not initialized!');
      return '''**$lga COUNCIL - Contact Required**

Visit: www.${lga.toLowerCase().replaceAll(' ', '')}.vic.gov.au
Contact the council for specific Local Law tree protection requirements.
''';
    }
    
    try {
      final prompt = '''You are an expert on Victorian local government tree protection laws.

TASK: Provide specific information about $lga Council's local law for tree protection.

Search your knowledge for:
1. The specific Local Law number (e.g., "Local Law No. 8 - Tree Protection")
2. Tree size thresholds (trunk circumference at 1m height, or height requirements)
3. Permit application fees (if known)
4. Exemptions (dead/dying trees, emergency, fire prevention)
5. Protected tree types (indigenous, significant, etc.)

FORMAT:
**$lga LOCAL LAW - TREE PROTECTION**

[Local Law number and year]

**PERMIT REQUIRED:**
• [Specific size thresholds with measurements]
• [Protected tree types]

**EXEMPTIONS:**
• [List specific exemptions]

**FEES & PROCESS:**
• Permit fee: [amount if known]
• Processing time: [timeframe if known]

**CONTACT:**
• Phone: [if known]
• Website: www.${lga.toLowerCase().replaceAll(' ', '')}.vic.gov.au

**IMPORTANT:** Always verify current requirements with the council before proceeding.

If you don't have specific information, say: "Specific local law details not available in database. Contact council directly."
''';
      
      print('🤖 AI researching LGA local laws for $lga...');
      
      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));
      
      final summary = response.text ?? '';
      if (summary.isEmpty || summary.contains('not available')) {
        return '''**$lga COUNCIL - LOCAL LAW INFORMATION**

Specific local law details not currently available in database.

**CONTACT:**
• Website: www.${lga.toLowerCase().replaceAll(' ', '')}.vic.gov.au/local-laws
• Ask for: Local Law tree protection requirements, permit fees, size thresholds

**Always verify current requirements with the council.**
''';
      }
      
      print('✅ LGA local laws summary generated');
      return summary + '''

---

⚠️ **CRITICAL DISCLAIMER:**
• AI-generated from training data (up to April 2024)
• May be OUTDATED or INACCURATE
• MUST verify with council before making decisions
• NOT legal advice
• Always check: www.${lga.toLowerCase().replaceAll(' ', '')}.vic.gov.au
''';
    } catch (e) {
      print('⚠️ LGA local laws generation failed: $e');
      return 'Contact $lga council: www.${lga.toLowerCase().replaceAll(' ', '')}.vic.gov.au';
    }
  }
}
