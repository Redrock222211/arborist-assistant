import 'package:flutter/material.dart';

/// Planning Dictionary Service - Provides comprehensive explanations for LGAs and overlays
/// 
/// ⚠️  DISCLAIMER: This information is provided as a general guide only.
/// Always verify current requirements with your local council and do your own research.
/// Planning scheme requirements can change and may vary by specific location.
/// 
class PlanningDictionaryService {
  
  /// Get LGA explanation and information
  static Map<String, dynamic> getLGAExplanation(String lgaName) {
    final lga = lgaName.toUpperCase();
    
    switch (lga) {
      case 'CITY OF YARRA':
        return {
          'name': 'City of Yarra',
          'description': 'Inner-city municipality covering Richmond, Cremorne, Collingwood, Fitzroy, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 40cm (400mm) or more are protected under Local Law No. 1 (General) 2018',
          'permit_required': 'Planning permit required for removal or pruning of significant trees',
          'heritage_areas': 'Extensive heritage overlays throughout the municipality',
          'contact': 'City of Yarra Planning Department',
          'phone': '(03) 9205 5555',
          'website': 'https://www.yarracity.vic.gov.au/planning',
          'special_notes': 'High heritage value area with strict tree protection',
        };
        
      case 'CITY OF MELBOURNE':
        return {
          'name': 'City of Melbourne',
          'description': 'Melbourne CBD and inner city areas including Docklands, Southbank, and North Melbourne',
          'tree_protection': 'Trees over 5m height or 40cm trunk diameter require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Extensive heritage overlays in CBD and surrounding areas',
          'contact': 'City of Melbourne Planning Department',
          'phone': '(03) 9658 9658',
          'website': 'https://www.melbourne.vic.gov.au/planning',
          'special_notes': 'CBD area with strict heritage and environmental protection',
        };
        
      case 'CITY OF PORT PHILLIP':
        return {
          'name': 'City of Port Phillip',
          'description': 'Coastal municipality covering St Kilda, Elwood, Port Melbourne, and South Melbourne',
          'tree_protection': 'Trees with trunk diameter of 50cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Significant heritage overlays in historic areas',
          'contact': 'City of Port Phillip Planning Department',
          'phone': '(03) 9209 6777',
          'website': 'https://www.portphillip.vic.gov.au/planning',
          'special_notes': 'Coastal area with heritage and environmental significance',
        };
        
      case 'CITY OF STONNINGTON':
        return {
          'name': 'City of Stonnington',
          'description': 'Inner-east municipality covering Prahran, Toorak, South Yarra, and Malvern',
          'tree_protection': 'Trees with trunk diameter of 40cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Extensive heritage overlays in historic residential areas',
          'contact': 'City of Stonnington Planning Department',
          'phone': '(03) 8290 1333',
          'website': 'https://www.stonnington.vic.gov.au/planning',
          'special_notes': 'High-value residential area with strict heritage protection',
        };
        
      case 'CITY OF BOROONDARA':
        return {
          'name': 'City of Boroondara',
          'description': 'Inner-east municipality covering Camberwell, Hawthorn, Kew, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 50cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Significant heritage overlays in historic residential areas',
          'contact': 'City of Boroondara Planning Department',
          'phone': '(03) 9278 4444',
          'website': 'https://www.boroondara.vic.gov.au/planning',
          'special_notes': 'Established residential area with heritage and environmental protection',
        };
        
      case 'CITY OF WHITTLESEA':
        return {
          'name': 'City of Whittlesea',
          'description': 'Northern growth area municipality covering Epping, Thomastown, Lalor, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 40cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Some heritage overlays in established areas',
          'contact': 'City of Whittlesea Planning Department',
          'phone': '(03) 9217 2170',
          'website': 'https://www.whittlesea.vic.gov.au/planning',
          'special_notes': 'Growth area with mix of established and new development',
        };
        
      case 'CITY OF MANNINGHAM':
        return {
          'name': 'City of Manningham',
          'description': 'Eastern municipality covering Doncaster, Templestowe, Bulleen, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 40cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Heritage overlays in historic areas',
          'contact': 'City of Manningham Planning Department',
          'phone': '(03) 9840 9333',
          'website': 'https://www.manningham.vic.gov.au/planning',
          'special_notes': 'Established residential area with significant vegetation',
        };
        
      case 'SHIRE OF NILLUMBIK':
        return {
          'name': 'Shire of Nillumbik',
          'description': 'Outer-eastern municipality covering Eltham, Diamond Creek, Hurstbridge, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 40cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Heritage overlays in historic areas',
          'contact': 'Shire of Nillumbik Planning Department',
          'phone': '(03) 9433 3111',
          'website': 'https://www.nillumbik.vic.gov.au/planning',
          'special_notes': 'Semi-rural area with significant environmental and heritage values',
        };
        
      case 'CITY OF MAROONDAH':
        return {
          'name': 'City of Maroondah',
          'description': 'Eastern municipality covering Ringwood, Croydon, Heathmont, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 40cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Heritage overlays in historic areas',
          'contact': 'City of Maroondah Planning Department',
          'phone': '(03) 9298 4598',
          'website': 'https://www.maroondah.vic.gov.au/planning',
          'special_notes': 'Established residential area with significant vegetation',
        };
        
      case 'CITY OF WHITEHORSE':
        return {
          'name': 'City of Whitehorse',
          'description': 'Eastern municipality covering Box Hill, Mitcham, Blackburn, and surrounding areas',
          'tree_protection': 'Trees with trunk diameter of 40cm or more at 1.4m height require planning permit',
          'permit_required': 'Planning permit required for significant trees and heritage trees',
          'heritage_areas': 'Heritage overlays in historic areas',
          'contact': 'City of Whitehorse Planning Department',
          'phone': '(03) 9262 6333',
          'website': 'https://www.whitehorse.vic.gov.au/planning',
          'special_notes': 'Established residential area with heritage and environmental protection',
        };
        
      default:
        return {
          'name': lgaName,
          'description': 'Local Government Area in Victoria',
          'tree_protection': 'Contact local council for current tree protection requirements',
          'permit_required': 'Contact local council for current permit requirements',
          'heritage_areas': 'Contact local council for heritage information',
          'contact': 'Local Council Planning Department',
          'phone': 'Contact local council',
          'website': 'Check local council website',
          'special_notes': 'Contact local council for specific requirements',
        };
    }
  }
  
  /// Get overlay explanation and information
  static Map<String, dynamic> getOverlayExplanation(String overlayCode) {
    final code = overlayCode.toUpperCase();
    
    switch (code) {
      case 'HO':
        return {
          'code': 'HO',
          'name': 'Heritage Overlay',
          'description': 'Heritage protection overlay - specific details vary by location',
          'what_it_means': 'Heritage protection applies - specific requirements depend on the schedule and location',
          'permit_required': 'YES - Planning permit required for works',
          'tree_removal': 'Planning permit required - check specific HO schedule for details',
          'contact': 'Contact local council heritage department',
          'impact_level': 'HIGH - Heritage protection',
          'action_required': 'Search for specific HO schedule details for this location',
        };
        
      case 'VPO':
        return {
          'code': 'VPO',
          'name': 'Vegetation Protection Overlay',
          'description': 'Vegetation protection overlay - specific rules depend on the schedule number',
          'what_it_means': 'VPO is the overarching overlay - check the specific schedule (VPO1, VPO2, etc.) for actual rules',
          'permit_required': 'Depends on schedule - check specific VPO schedule',
          'tree_removal': 'Rules vary by schedule - check specific VPO schedule number',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Schedule dependent',
          'action_required': 'Search for specific VPO schedule details (VPO1, VPO2, etc.) for this location',
        };
        
      case 'VPO1':
        return {
          'code': 'VPO1',
          'name': 'Vegetation Protection Overlay Schedule 1',
          'description': 'VPO1 - Native vegetation protection (varies by council)',
          'what_it_means': 'VPO1 rules vary by council - check specific council schedule',
          'permit_required': 'Varies by council - check specific schedule',
          'tree_removal': 'Varies by council - check specific schedule',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Council specific',
          'action_required': 'Check specific VPO1 schedule for your council',
        };
        
      case 'VPO1_BALLARAT':
        return {
          'code': 'VPO1_BALLARAT',
          'name': 'VPO1 - Ballarat City Council',
          'description': 'To protect all native vegetation for its contribution to area character, habitat value, and land management',
          'what_it_means': 'A permit is required to remove, destroy or lop any native vegetation with a height over one metre',
          'permit_required': 'YES - for native vegetation over 1m height',
          'tree_removal': 'Permit required for native vegetation over 1m height',
          'contact': 'Ballarat City Council Planning Department',
          'impact_level': 'HIGH - Native vegetation protection',
          'exemptions': 'Pruning to improve health/appearance without retarding normal growth',
        };
        
      case 'VPO1_BAWBAW':
        return {
          'code': 'VPO1_BAWBAW',
          'name': 'VPO1 - Baw Baw Shire Council',
          'description': 'To ensure buildings and works are sited and designed having regard to the value of remnant vegetation in Rokeby',
          'what_it_means': 'A permit is required to remove, destroy or lop native vegetation',
          'permit_required': 'YES - for native vegetation',
          'tree_removal': 'Permit required for native vegetation removal',
          'contact': 'Baw Baw Shire Council Planning Department',
          'impact_level': 'HIGH - Native vegetation protection',
          'exemptions': 'Check council website for specific exemptions',
        };
        
      case 'VPO1_BAYSIDE':
        return {
          'code': 'VPO1_BAYSIDE',
          'name': 'VPO1 - Bayside City Council',
          'description': 'To maintain the quality of the remaining fauna habitat in Bayside\'s coastal reserves and to create additional habitat',
          'what_it_means': 'A permit is required to remove, destroy or lop native vegetation',
          'permit_required': 'YES - for native vegetation',
          'tree_removal': 'Permit required for native vegetation removal',
          'contact': 'Bayside City Council Planning Department',
          'impact_level': 'HIGH - Native vegetation protection',
          'exemptions': 'Check council website for specific exemptions',
        };
        
      case 'VPO2':
        return {
          'code': 'VPO2',
          'name': 'Vegetation Protection Overlay Schedule 2',
          'description': 'VPO2 - Full vegetation protection (varies by council)',
          'what_it_means': 'VPO2 rules vary by council - check specific council schedule',
          'permit_required': 'Varies by council - check specific schedule',
          'tree_removal': 'Varies by council - check specific schedule',
          'contact': 'Contact local council planning department',
          'impact_level': 'HIGH - Council specific',
          'action_required': 'Check specific VPO2 schedule for your council',
        };
        
      case 'VPO2_BASSCOAST':
        return {
          'code': 'VPO2_BASSCOAST',
          'name': 'VPO2 - Bass Coast Shire Council',
          'description': 'To protect and enhance existing indigenous and larger native species within the urban area of Phillip Island',
          'what_it_means': 'A permit is required to remove, destroy or lop a native tree with a trunk girth of at least 1 metre (measured at 30cm above ground) OR any vegetation specified in the schedule\'s list',
          'permit_required': 'YES - for native trees with 1m+ trunk girth or specified vegetation',
          'tree_removal': 'Permit required for native trees with 1m+ trunk girth or specified vegetation',
          'contact': 'Bass Coast Shire Council Planning Department',
          'impact_level': 'HIGH - Native vegetation protection',
          'exemptions': 'Pruning for maintenance by qualified arborist to AS4373-1996; Removal of dead vegetation; Works by public land managers',
        };
        
            case 'VPO3':
        return {
          'code': 'VPO3',
          'name': 'Vegetation Protection Overlay Schedule 3',
          'description': 'VPO3 - Specific vegetation protection (varies by council)',
          'what_it_means': 'VPO3 rules vary by council - check specific council schedule',
          'permit_required': 'Varies by council - check specific schedule',
          'tree_removal': 'Varies by council - check specific schedule',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Council specific',
          'action_required': 'Check specific VPO3 schedule for your council',
        };
        
      case 'VPO3_BALLARAT':
        return {
          'code': 'VPO3_BALLARAT',
          'name': 'VPO3 - Ballarat City Council',
          'description': 'To retain the amenity and aesthetic character of mature garden and street trees within the Ballarat Golf Club redevelopment area',
          'what_it_means': 'A permit is required to remove vegetation that is more than 4 metres high',
          'permit_required': 'YES - for vegetation over 4m height',
          'tree_removal': 'Permit required for vegetation over 4m height',
          'contact': 'Ballarat City Council Planning Department',
          'impact_level': 'MEDIUM - Height-based protection',
          'exemptions': 'Pruning to improve health/appearance without retarding normal growth; Trees identified for removal in Council-approved Development Plan',
        };
        
      case 'VPO3_BANYULE':
        return {
          'code': 'VPO3_BANYULE',
          'name': 'VPO3 - Banyule City Council',
          'description': 'To retain and enhance vegetation, particularly tall trees, that contributes to the identified Garden Suburban character of the area',
          'what_it_means': 'A permit is required to remove, destroy or lop any vegetation',
          'permit_required': 'YES - for any vegetation',
          'tree_removal': 'Permit required for any vegetation removal',
          'contact': 'Banyule City Council Planning Department',
          'impact_level': 'HIGH - Full vegetation protection',
          'exemptions': 'Exotic vegetation <5m high and <0.5m trunk circumference; Environmental weeds; Pruning to improve health/structure/appearance; Pruning/removal to prevent damage to services',
        };
        
        case 'ESO':
        return {
          'code': 'ESO',
          'name': 'Environmental Significance Overlay',
          'description': 'Environmental protection overlay - protects areas of environmental significance',
          'what_it_means': 'Planning permit required to remove, destroy or lop any vegetation, including dead vegetation',
          'permit_required': 'YES - for vegetation removal (with exceptions)',
          'tree_removal': 'Permit required unless schedule specifically states no permit needed, or Clause 42.01-3 table states no permit needed, or native vegetation precinct plan applies',
          'contact': 'Contact local council planning department',
          'impact_level': 'HIGH - Environmental protection',
          'action_required': 'Check ESO schedule (ESO1, ESO2, ESO3) and Clause 42.01-3 table for specific exemptions',
        };
        
      case 'ESO4_BANYULE':
        return {
          'code': 'ESO4_BANYULE',
          'name': 'ESO4 - Banyule City Council',
          'description': 'To protect and enhance trees and areas of vegetation that are significant, as listed in the Banyule City Council Significant Trees Register',
          'what_it_means': 'A permit is required to remove, destroy or lop any significant tree or area of vegetation specified in the table to the clause',
          'permit_required': 'YES - for significant trees and vegetation',
          'tree_removal': 'Permit required for significant trees and vegetation removal',
          'contact': 'Banyule City Council Planning Department',
          'impact_level': 'HIGH - Significant tree protection',
          'exemptions': 'Pruning to maintain or improve health/appearance; Pruning for safe operation of rail services under agreement; Removal/lopping if permit granted under Heritage Act 1995; Works outside critical root zone (5m beyond drip-line)',
        };
        
      case 'ESO6_BRIMBANK':
        return {
          'code': 'ESO6_BRIMBANK',
          'name': 'ESO6 - Brimbank City Council',
          'description': 'To protect and enhance ecosystems, species and genetic diversity in areas of identified biological significance, including important grasslands and woodlands',
          'what_it_means': 'A permit is required to remove, destroy or lop any vegetation, including dead vegetation, unless exempt',
          'permit_required': 'YES - for vegetation removal (with exceptions)',
          'tree_removal': 'Permit required for vegetation removal unless exempt',
          'contact': 'Brimbank City Council Planning Department',
          'impact_level': 'HIGH - Ecosystem protection',
          'exemptions': 'Removal of non-indigenous vegetation or proclaimed weeds; Works by public authorities for revegetation; Pruning for maintenance where no more than one third of foliage is removed (does not apply to tree trunks)',
        };
        
      case 'DDO':
        return {
          'code': 'DDO',
          'name': 'Design and Development Overlay',
          'description': 'Controls the design and development of buildings and works to maintain character',
          'what_it_means': 'Design controls apply. Tree removal may be affected by design requirements.',
          'permit_required': 'YES - Planning permit required for development',
          'tree_removal': 'May require planning permit depending on design impact',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Design control focus',
          'action_required': 'Check specific DDO schedule for your location',
        };
        
      case 'SLO':
        return {
          'code': 'SLO',
          'name': 'Significant Landscape Overlay',
          'description': 'Protects significant landscapes, views, and visual character of areas',
          'what_it_means': 'Landscape protection applies. Tree removal may affect views and landscape character.',
          'permit_required': 'YES - Planning permit required for landscape works',
          'tree_removal': 'Planning permit required if it affects landscape character',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Landscape protection focus',
          'action_required': 'Check specific SLO schedule for your location',
        };
        
      case 'SLO1_ALPINE':
        return {
          'code': 'SLO1_ALPINE',
          'name': 'SLO1 - Alpine Shire Council',
          'description': 'To protect the visual values of the landscape, including views to mountains and ranges, and maintain the rural landscape character of the Upper Kiewa Valley',
          'what_it_means': 'Check Council Website. Permit may be required for buildings and works that impact landscape character.',
          'permit_required': 'Check Council Website',
          'tree_removal': 'Check Council Website',
          'contact': 'Alpine Shire Council Planning Department',
          'impact_level': 'MEDIUM - Landscape protection',
          'action_required': 'Check Council Website for specific requirements',
        };
        
      case 'LSIO':
        return {
          'code': 'LSIO',
          'name': 'Land Subject to Inundation Overlay',
          'description': 'Identifies land that may be subject to flooding or inundation',
          'what_it_means': 'Flood risk area. Tree removal may affect drainage and flood management.',
          'permit_required': 'YES - Planning permit required for works',
          'tree_removal': 'Planning permit required with drainage considerations',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Flood risk management',
          'action_required': 'Check specific LSIO schedule for your location',
        };
        
      case 'BMO':
        return {
          'code': 'BMO',
          'name': 'Bushfire Management Overlay',
          'description': 'Identifies areas at risk from bushfire and requires bushfire protection measures',
          'what_it_means': 'Bushfire risk area. Tree removal may be required for bushfire protection.',
          'permit_required': 'YES - Planning permit required with bushfire considerations',
          'tree_removal': 'May be required for bushfire protection, permit needed',
          'contact': 'Contact local council planning department',
          'impact_level': 'HIGH - Bushfire safety priority',
          'action_required': 'Check specific BMO schedule for your location',
        };
        
      default:
        return {
          'code': overlayCode,
          'name': 'Unknown Overlay',
          'description': 'Contact local council for information about this overlay',
          'what_it_means': 'Contact local council for specific requirements',
          'permit_required': 'Contact local council for permit requirements',
          'tree_removal': 'Contact local council for tree removal requirements',
          'contact': 'Contact local council planning department',
          'impact_level': 'UNKNOWN - Contact council for details',
          'action_required': 'Contact local council for specific requirements',
        };
    }
  }
  
  /// Get zone explanation and information
  static Map<String, dynamic> getZoneExplanation(String zoneCode) {
    final code = zoneCode.toUpperCase();
    
    switch (code) {
      case 'GRZ':
        return {
          'code': 'GRZ',
          'name': 'General Residential Zone',
          'description': 'Standard residential zone for housing and associated uses',
          'what_it_means': 'Residential development with tree protection requirements',
          'permit_required': 'YES - Planning permit required for tree removal',
          'tree_removal': 'Planning permit required for significant trees',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Standard residential protection',
          'action_required': 'Check specific GRZ schedule for your location',
        };
        
      case 'C1Z':
        return {
          'code': 'C1Z',
          'name': 'Commercial 1 Zone',
          'description': 'Commercial zone for retail, office, and commercial activities',
          'what_it_means': 'Commercial development with planning controls',
          'permit_required': 'YES - Planning permit required for tree removal',
          'tree_removal': 'Planning permit required for significant trees',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Commercial development focus',
          'action_required': 'Check specific C1Z schedule for your location',
        };
        
      case 'IN1Z':
        return {
          'code': 'IN1Z',
          'name': 'Industrial 1 Zone',
          'description': 'Industrial zone for manufacturing, processing, and industrial activities',
          'what_it_means': 'Industrial development with environmental controls',
          'permit_required': 'YES - Planning permit required for tree removal',
          'tree_removal': 'Planning permit required for significant trees',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Industrial development focus',
          'action_required': 'Check specific IN1Z schedule for your location',
        };
        
      case 'PUZ':
        return {
          'code': 'PUZ',
          'name': 'Public Use Zone',
          'description': 'Zone for public land and facilities',
          'what_it_means': 'Public land with specific use requirements',
          'permit_required': 'YES - Planning permit required for tree removal',
          'tree_removal': 'Planning permit required for significant trees',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Public land management',
          'action_required': 'Check specific PUZ schedule for your location',
        };
        
      case 'TREE_PROTECTION_BOROONDARA':
        return {
          'code': 'TREE_PROTECTION_BOROONDARA',
          'name': 'Tree Protection Local Law - Boroondara City Council',
          'description': 'To protect \'Significant\' and \'Canopy\' trees. Significant trees are on a register for their heritage, size, rarity or ecological value. Canopy trees are protected based on size.',
          'what_it_means': 'Permit required to remove a \'Significant Tree\'. Permit required to remove a \'Canopy Tree\' (trunk circumference >=110cm at 1.4m height OR >=150cm at ground level). This applies even if the tree is dead or a weed species.',
          'permit_required': 'YES - for Significant and Canopy trees',
          'tree_removal': 'Permit required for Significant and Canopy trees',
          'contact': 'Boroondara City Council Planning Department',
          'impact_level': 'HIGH - Tree protection',
          'exemptions': 'Pruning of \'Canopy Trees\' to Australian Standards by a qualified arborist',
        };
        
      case 'VPO_MONASH':
        return {
          'code': 'VPO_MONASH',
          'name': 'VPO - Monash City Council',
          'description': 'To preserve existing vegetation, encourage regeneration of native plants, and enhance habitat',
          'what_it_means': 'A planning permit is needed to remove or destroy vegetation that is higher than 10m AND has a trunk circumference greater than 50cm (16cm diameter) at 120cm above ground level',
          'permit_required': 'YES - for vegetation over 10m height AND over 50cm trunk circumference',
          'tree_removal': 'Permit required for vegetation over 10m height AND over 50cm trunk circumference',
          'contact': 'Monash City Council Planning Department',
          'impact_level': 'MEDIUM - Size-based protection',
          'exemptions': 'Dead vegetation; Certain specified tree species (willows, radiata pines, etc.); Vegetation that presents an immediate risk to personal injury or property',
        };
        
      case 'MULTIPLE_SURFCOAST':
        return {
          'code': 'MULTIPLE_SURFCOAST',
          'name': 'Multiple Overlays - Surf Coast Shire Council',
          'description': 'Vegetation is protected under various controls including ESO, SLO, VPO, Salinity Management Overlay, and Heritage Overlay',
          'what_it_means': 'Permit required for: removal of any native vegetation from a property >4000m²; removal of any vegetation within an ESO; removal of vegetation specified in an SLO or VPO schedule; removal within a Salinity Management Overlay; removal of some trees under a Heritage Overlay',
          'permit_required': 'YES - for various vegetation works depending on overlay',
          'tree_removal': 'Permit required for various vegetation works depending on overlay',
          'contact': 'Surf Coast Shire Council Planning Department',
          'impact_level': 'HIGH - Multiple overlay protection',
          'exemptions': 'Bushfire clearing exemptions exist for properties in a Bushfire Management Overlay (BMO) or Bushfire Prone Area (BPA) around existing homes',
        };
        
      case 'FZ':
        return {
          'code': 'FZ',
          'name': 'Farming Zone',
          'description': 'Zone for agricultural and farming activities',
          'what_it_means': 'Agricultural land with environmental protection',
          'permit_required': 'YES - Planning permit required for tree removal',
          'tree_removal': 'Planning permit required for significant trees',
          'contact': 'Contact local council planning department',
          'impact_level': 'MEDIUM - Agricultural land management',
          'action_required': 'Check specific FZ schedule for your location',
        };
        
      case 'SIGNIFICANT_TREE_CASEY':
        return {
          'code': 'SIGNIFICANT_TREE_CASEY',
          'name': 'Significant Tree Register / Overlays - Casey City Council',
          'description': 'To identify and protect the most significant trees in Casey, and protect other trees and vegetation via Planning Scheme Overlays (e.g., Heritage, Environmental Significance)',
          'what_it_means': 'A permit is required to remove or conduct adverse works on a tree listed on the Significant Tree Register or protected by an overlay',
          'permit_required': 'YES - for Significant Tree Register trees and overlay-protected trees',
          'tree_removal': 'Permit required for Significant Tree Register trees and overlay-protected trees',
          'contact': 'Casey City Council Planning Department',
          'impact_level': 'HIGH - Significant tree protection',
          'action_required': 'Check specific overlay schedule or Significant Tree Register details',
        };
        
      case 'VPO_ESO_DDO_CARDINIA':
        return {
          'code': 'VPO_ESO_DDO_CARDINIA',
          'name': 'VPO / ESO / DDO - Cardinia Shire Council',
          'description': 'To protect vegetation under various overlays including Environmental Significance, Vegetation Protection, and Design and Development Overlays',
          'what_it_means': 'A planning permit is required to remove, destroy or lop vegetation if the land is covered by an applicable overlay',
          'permit_required': 'YES - for vegetation works under applicable overlays',
          'tree_removal': 'Permit required for vegetation works under applicable overlays',
          'contact': 'Cardinia Shire Council Planning Department',
          'impact_level': 'HIGH - Multiple overlay protection',
          'action_required': 'Check specific overlay schedule in the Cardinia Planning Scheme',
        };
        
      case 'VPO_EMO_EASTGIPPSLAND':
        return {
          'code': 'VPO_EMO_EASTGIPPSLAND',
          'name': 'VPO / EMO - East Gippsland Shire Council',
          'description': 'To preserve and protect significant native, indigenous and introduced vegetation. VPO applies to both native and exotic vegetation. EMO applies to vegetation in erosion-prone areas',
          'what_it_means': 'Permit required unless exempt. General exemptions include dead trees <40cm diameter, personal use on >10ha properties, minimum for boundary fence (4m width), properties <0.4ha',
          'permit_required': 'YES - unless exempt',
          'tree_removal': 'Permit required unless exempt',
          'contact': 'East Gippsland Shire Council Planning Department',
          'impact_level': 'MEDIUM - Conditional protection',
          'exemptions': 'Dead vegetation; Minimum for boundary fence; Unsafe trees (with arborist report); Personal use (EMO); Small residential properties with low slope (EMO)',
        };
        
      default:
        return {
          'code': zoneCode,
          'name': 'Unknown Zone',
          'description': 'Contact local council for information about this zone',
          'what_it_means': 'Contact local council for specific requirements',
          'permit_required': 'Contact local council for permit requirements',
          'tree_removal': 'Contact local council for tree removal requirements',
          'contact': 'Contact local council planning department',
          'impact_level': 'UNKNOWN - Contact council for details',
          'examples': 'Contact local council for examples',
        };
    }
  }
  
  /// Get comprehensive planning information for a location
  static Map<String, dynamic> getComprehensivePlanningInfo({
    required String lga,
    required List<Map<String, dynamic>> overlays,
    required List<Map<String, dynamic>> zones,
  }) {
    final lgaInfo = getLGAExplanation(lga);
    final overlayExplanations = overlays.map((overlay) {
      final code = overlay['code'] ?? 'Unknown';
      return {
        'overlay_data': overlay,
        'explanation': getOverlayExplanation(code),
      };
    }).toList();
    
    final zoneExplanations = zones.map((zone) {
      final code = zone['code'] ?? 'Unknown';
      return {
        'zone_data': zone,
        'explanation': getZoneExplanation(code),
      };
    }).toList();
    
    return {
      'lga': lgaInfo,
      'overlays': overlayExplanations,
      'zones': zoneExplanations,
      'summary': {
        'total_overlays': overlays.length,
        'total_zones': zones.length,
        'highest_protection': _getHighestProtectionLevel(overlayExplanations),
        'permit_required': overlays.isNotEmpty || zones.isNotEmpty,
      },
    };
  }
  
  /// Get the highest protection level from overlays
  static String _getHighestProtectionLevel(List<Map<String, dynamic>> overlayExplanations) {
    if (overlayExplanations.isEmpty) return 'None';
    
    final levels = overlayExplanations.map((o) => o['explanation']['impact_level']).toList();
    
    if (levels.contains('HIGH')) return 'HIGH';
    if (levels.contains('MEDIUM')) return 'MEDIUM';
    return 'LOW';
  }
}
