import 'package:hive/hive.dart';
import '../models/tree_permit.dart';
import 'package:uuid/uuid.dart';
import 'vicplan_service.dart';
import 'planning_ai_service.dart';

class TreePermitService {
  static const String boxName = 'tree_permits';

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TreePermitAdapter());
    }
    await Hive.openBox<TreePermit>(boxName);
    
    // Initialize AI service for intelligent permit summaries
    await PlanningAIService.initialize();
  }

  static Future<void> addPermit(TreePermit permit) async {
    final box = Hive.box<TreePermit>(boxName);
    await box.add(permit);
  }

  static List<TreePermit> getPermitsForSite(String siteId) {
    final box = Hive.box<TreePermit>(boxName);
    return box.values.where((permit) => permit.siteId == siteId).toList();
  }

  static Future<void> deletePermit(String permitId) async {
    final box = Hive.box<TreePermit>(boxName);
    final permit = box.values.firstWhere((p) => p.id == permitId);
    await permit.delete();
  }

  // Enhanced permit lookup using Victorian Planning API
  static Future<TreePermit> lookupPermit({
    required String siteId,
    required String address,
    double? latitude,
    double? longitude,
    required String searchMethod,
  }) async {
    print('🔍 TreePermitService: Looking up permit for: $address');
    
    String councilName = 'Unknown Council';
    String lgaKey = 'unknown';
    List<Map<String, dynamic>> overlays = [];
    List<Map<String, dynamic>> zones = [];
    String aiGeneratedSummary = '';
    
    try {
      // Try VicPlan MapShare API first
      print('🔍 TreePermitService: Attempting VicPlan API lookup...');
      final vicplanResult = await VicPlanService.lookupAddress(address)
          .timeout(const Duration(seconds: 40));
      
      if (vicplanResult['success'] == true) {
        // Extract LGA
        if (vicplanResult['lga'] != null) {
          final lga = vicplanResult['lga'];
          if (lga is Map) {
            councilName = lga['LGA'] ?? lga['lga'] ?? lga['LGA_NAME'] ?? 'Unknown Council';
          } else {
            councilName = lga.toString();
          }
          lgaKey = vicplanResult['lga_key'] ?? _extractLGAKey(councilName);
          print('✅ TreePermitService: API found LGA: $councilName (key: $lgaKey)');
        }
        
        // Extract overlays and zones for AI
        if (vicplanResult['overlays'] != null) {
          overlays = List<Map<String, dynamic>>.from(vicplanResult['overlays']);
        }
        if (vicplanResult['zones'] != null) {
          zones = List<Map<String, dynamic>>.from(vicplanResult['zones']);
        }
        
        // Generate AI summary from real planning data
        if (councilName != 'Unknown Council' && (overlays.isNotEmpty || zones.isNotEmpty)) {
          print('🤖 Generating AI permit summary...');
          try {
            aiGeneratedSummary = await PlanningAIService.generatePermitSummary(
              lga: councilName,
              overlays: overlays,
              zones: zones,
            ).timeout(const Duration(seconds: 20));
            print('✅ AI summary generated successfully');
          } catch (aiError) {
            print('⚠️ AI summary failed: $aiError');
          }
        }
      }
      
      if (councilName == 'Unknown Council') {
        throw Exception('API returned no LGA data');
      }
    } catch (e) {
      print('⚠️ TreePermitService: API lookup failed ($e), using local detection');
      
      // Fallback to local council detection
      final addressLower = address.toLowerCase();
    
    if (addressLower.contains('whittlesea') || addressLower.contains('epping') || addressLower.contains('mill park') || addressLower.contains('south morang')) {
      councilName = 'City of Whittlesea';
      lgaKey = 'whittlesea';
    } else if (addressLower.contains('melbourne') || addressLower.contains('cbd') || addressLower.contains('3000')) {
      councilName = 'City of Melbourne';
      lgaKey = 'melbourne';
    } else if (addressLower.contains('port phillip') || addressLower.contains('st kilda') || addressLower.contains('south melbourne')) {
      councilName = 'City of Port Phillip';
      lgaKey = 'port_phillip';
    } else if (addressLower.contains('yarra') || addressLower.contains('collingwood') || addressLower.contains('fitzroy')) {
      councilName = 'City of Yarra';
      lgaKey = 'yarra';
    } else if (addressLower.contains('darebin') || addressLower.contains('preston') || addressLower.contains('northcote') || addressLower.contains('reservoir')) {
      councilName = 'City of Darebin';
      lgaKey = 'darebin';
    } else if (addressLower.contains('moreland') || addressLower.contains('brunswick') || addressLower.contains('coburg')) {
      councilName = 'City of Moreland';
      lgaKey = 'moreland';
    } else if (addressLower.contains('banyule') || addressLower.contains('heidelberg') || addressLower.contains('ivanhoe')) {
      councilName = 'City of Banyule';
      lgaKey = 'banyule';
    } else if (addressLower.contains('boroondara') || addressLower.contains('kew') || addressLower.contains('hawthorn')) {
      councilName = 'City of Boroondara';
      lgaKey = 'boroondara';
    } else if (addressLower.contains('glen eira') || addressLower.contains('caulfield') || addressLower.contains('bentleigh')) {
      councilName = 'City of Glen Eira';
      lgaKey = 'glen_eira';
    } else if (addressLower.contains('monash') || addressLower.contains('glen waverley') || addressLower.contains('oakleigh')) {
      councilName = 'City of Monash';
      lgaKey = 'monash';
    }
    
      print('✅ TreePermitService: Local detection found: $councilName (key: $lgaKey)');
    }
    
    // Use AI summary if available, otherwise use static permit info
    String finalNotes;
    String finalRequirements;
    
    if (aiGeneratedSummary.isNotEmpty) {
      print('✅ TreePermitService: Using AI-generated summary');
      finalNotes = aiGeneratedSummary;
      finalRequirements = 'AI-interpreted from Victorian planning data';
    } else {
      print('⚠️ TreePermitService: Using static permit info (AI unavailable)');
      final permitSummary = VicPlanService.getPermitSummary(lgaKey);
      final formattedConditions = VicPlanService.formatPermitConditions(lgaKey);
      finalNotes = formattedConditions;
      finalRequirements = permitSummary['requirements'] ?? 'Contact council for specific requirements';
    }
    
    print('✅ TreePermitService: Using council: $councilName');
    
    return TreePermit(
      id: const Uuid().v4(),
      siteId: siteId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      councilName: councilName,
      permitStatus: 'Permit may be required',
      permitType: 'Tree Removal Permit',
      requirements: finalRequirements,
      notes: finalNotes,
      searchDate: DateTime.now(),
      searchMethod: searchMethod,
    );
  }
  
  // Extract LGA key from name
  static String _extractLGAKey(dynamic lga) {
    if (lga is Map && lga.containsKey('key')) {
      return lga['key'];
    }
    
    final lgaName = lga is String ? lga : (lga['name'] ?? lga.toString());
    return lgaName.toLowerCase()
        .replaceAll('city of ', '')
        .replaceAll('shire of ', '')
        .replaceAll('rural city of ', '')
        .replaceAll(' ', '_');
  }
}
