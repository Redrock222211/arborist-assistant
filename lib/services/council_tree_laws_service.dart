import 'dart:convert';

class CouncilTreeLawsService {
  // Real Victorian Council Tree Protection Laws Data
  static const String _councilData = '''
Council,OverlaySchedule,Purpose,RemovalTrigger,PruningTrigger,KeyExemptions,SourceURL
Alpine Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.alpineshire.vic.gov.au/planning-and-building/planning/planning-permits"
Ararat Rural City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.ararat.vic.gov.au/planning-building/sites-zoning-applications"
Ballarat City,,Exceptional/Significant trees & native vegetation,"Planning permit for removal, destruction or lopping of native vegetation (Clause 52.17) or one tree via VicSmart where applicable",,,"https://www.ballarat.vic.gov.au/property/statutory-planning/planning/planning-help"
Bass Coast Shire,,Local law + planning,"Local Law permit required to remove/prune trees on private property; planning permit may be required for native vegetation/overlays",,, "https://www.basscoast.vic.gov.au/services/building-planning/trees-and-vegetation"
Baw Baw Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.bawbawshire.vic.gov.au/Plan-and-Build/Planning-permits/Permit-Information/Native-Vegetation"
Benalla Rural City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.benalla.vic.gov.au/Planning-and-building/Planning-permits/Native-vegetation-and-permits"
Banyule City,,Tree/vegetation protection page,"Permit may be required based on size/species and overlays (see council guidance)",,, "https://www.banyule.vic.gov.au/Planning-building/Protection-for-trees-and-vegetation"
Bayside City,VPO/NCO in mapped areas,Planning overlays and local law protect trees,"Permit often required to remove native vegetation or protected trees in mapped areas; check VPO/Local Law",Pruning near dwellings has limited allowances per guidance,, "https://yoursay.bayside.vic.gov.au/trees-private-property"
Boroondara City,,Tree Protection Local Law & planning overlays,"Permit required to remove a canopy tree or works within 2m of trunk; Significant Tree: permit to prune/remove or works within TPZ",,,"https://www.boroondara.vic.gov.au/services/planning-and-building/building/works-permits/trees-and-construction/tree-works-permits"
Buloke Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.buloke.vic.gov.au/planning"
Campaspe Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.campaspe.vic.gov.au/Planning-building/Planning/Planning-permits/Planning-permit-information"
Cardinia Shire,,Check Council Website,Check Council Website,Check Council Website,Check Council Website,"https://www.cardinia.vic.gov.au/planning"
Casey City,,Significant Tree Strategy & register,"Check Council Website for triggers and permit pathways; planning overlays may also apply",,,"https://www.casey.vic.gov.au/policies-strategies/casey-significant-tree-strategy-incorporating-significant-tree-register"
Central Goldfields Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.centralgoldfields.vic.gov.au/Planning-Building/Planning/Planning-Permits"
Colac Otway Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.colacotway.vic.gov.au/Development/Planning/Planning-application-guides"
Corangamite Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.corangamite.vic.gov.au/Development/Planning/Planning-FAQs"
Darebin City,,Significant Tree Local Law,"Significant tree: single or combined trunk circumference >100cm at 1.5m and taller than 8m requires permit",,,"https://www.darebin.vic.gov.au/Planning-and-building/Planning/Planning-for-your-property/Trees-and-vegetation"
East Gippsland Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.eastgippsland.vic.gov.au/develop/planning-permits/planning-forms-and-guides#nativevegetation"
Frankston City,,Tree Protection Local Law,"Permit required to remove/prune protected trees per Local Law No.22 (e.g., larger trees); planning controls may also apply",,BPA and weed species exemptions in law factsheet,"https://www.frankston.vic.gov.au/Community-and-Health/Environment/Trees-and-vegetation/Request-Local-Law-permit-for-pruning-or-removal-of-a-private-tree"
Gannawarra Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.gannawarra.vic.gov.au/Develop-and-Build/Planning/Planning-Applications"
Glen Eira City,,Canopy Tree Protection Local Law,"Permit required to prune/remove or do works within TPZ of a Canopy Tree or Classified Tree. Canopy Tree triggers include: palm ≥8m; any tree ≥5m; trunk circumference ≥140cm at ground or at 1.4m; combined trunks ≥140cm at 1.4m",Minor pruning up to 10% of canopy once per year without permit; hazard-safe works after storms,See page exemptions, "https://www.gleneira.vic.gov.au/services/planning-and-building/building/permits/canopy-tree-protection"
Glenelg Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.glenelg.vic.gov.au/Resident/Planning-and-building/Planning/Planning-permits"
Golden Plains Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.goldenplains.vic.gov.au/resident/planning-and-building/planning/planning-permits"
Greater Bendigo City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.bendigo.vic.gov.au/planning/planning-permits/do-i-need-planning-permit"
Greater Dandenong City,,Local law (Protected Trees),"Permit generally required for protected trees (e.g., stem diameter ≥40cm at 1.4m) or noxious weeds—see council",,, "https://www.greaterdandenong.vic.gov.au/planning-and-building/planning-permits/trees-and-vegetation"
Greater Geelong City,,,Native vegetation / overlays may require planning permit; check property report and overlays,,,,"https://www.geelongaustralia.com.au/planning/default.aspx"
Greater Shepparton City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://greatershepparton.com.au/business/planning-and-building/planning-permits"
Hepburn Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.hepburn.vic.gov.au/planning-planning-scheme"
Hindmarsh Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.hindmarsh.vic.gov.au/planning"
Hobsons Bay City,,Check Council Website,Check Council Website,Check Council Website,, "https://www.hobsonsbay.vic.gov.au/Planning-building-and-development/Planning/Planning-permits"
Horsham Rural City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.hrcc.vic.gov.au/Residents/Planning-and-Permits/Planning/Planning-Permits"
Hume City,,,Native vegetation removal and overlays may require a planning permit; check property report,,,,"https://www.hume.vic.gov.au/Residents/Planning-and-building/Planning/Planning-scheme-property-report"
Indigo Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.indigoshire.vic.gov.au/Develop/Planning-and-building/Planning-permits"
Kingston City,,Community Local Law + Significant Tree Register,"Local Law permit required for pruning/removal of private trees meeting protected criteria; planning overlays may also apply",,, "https://www.kingston.vic.gov.au/environment/trees-plants-and-nature-strips/private-trees"
Knox City,,Check Council Website,Check Council Website,Check Council Website,, "https://www.knox.vic.gov.au/planning-and-building"
Latrobe City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.latrobe.vic.gov.au/planning-and-building/planning-permits/do-i-need-permit"
Loddon Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.loddon.vic.gov.au/Plan-and-build/Planning/Planning-permits"
Macedon Ranges Shire,,,Native vegetation (Clause 52.17) may require a planning permit; check overlays too,,,,"https://www.mrsc.vic.gov.au/building-planning/planning/apply-for-a-planning-permit"
Manningham City,,Check Council Website,Check Council Website,Check Council Website,, "https://www.manningham.vic.gov.au/planning-and-building"
Mansfield Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.mansfield.vic.gov.au/plan-and-build/planning-permits"
Maribyrnong City,,Significant Tree Register,"Significant trees listed require protection/permits; planning overlays may also apply",,, "https://www.maribyrnong.vic.gov.au/"
Maroondah City,,Check Council Website,Check Council Website,Check Council Website,, "https://www.maroondah.vic.gov.au/Development/Planning"
Melbourne City,,Exceptional/Significant tree registers + planning overlays,Protected/registered trees and overlays may require permits,, "https://www.melbourne.vic.gov.au/building-and-development/urban-planning/Pages/trees.aspx"
Melton City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.melton.vic.gov.au/Services/Building-Planning/Planning/Do-I-need-a-planning-permit"
Mildura Rural City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.mildura.vic.gov.au/Services/Planning/Do-I-need-a-planning-permit"
Mitchell Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.mitchellshire.vic.gov.au/planning-and-building/planning/plan-applications"
Moira Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.moira.vic.gov.au/Residents/Planning-and-Building/Planning/Planning-Permits"
Monash City,VPO in mapped areas,Planning overlays protect vegetation,"Where VPO applies, planning permit may be required to remove a tree",,, "https://www.monash.vic.gov.au/Planning-Development/Planning/Vegetation-Protection-Overlay"
Moonee Valley City,,Activities & General Amenities Local Law + Guidelines,"Permit required to do works to Significant or Canopy Trees in accordance with Tree & Canopy Protection Guidelines",,, "https://mvcc.vic.gov.au/local-laws/"
Moorabool Shire,,,Native vegetation/overlays may require a planning permit; council guidance page provided,,,,"https://www.moorabool.vic.gov.au/Building-and-planning/Do-I-need-a-permit/Remove-destroy-or-lop-a-tree-or-other-vegetation-on-your-property"
Moreland (Merri-bek) City,,Tree Works Permit,"Permit required for removal or pruning (e.g. >15% canopy) of mature/significant trees per council definitions",,, "https://www.merri-bek.vic.gov.au/building-and-planning/trees/tree-works-permit/"
Mount Alexander Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.mountalexander.vic.gov.au/Planning_permits"
Moyne Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.moyne.vic.gov.au/Residents/Planning/Planning-permits"
Murrindindi Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.murrindindi.vic.gov.au/Discover-Council/Publications/Native-Vegetation-Removal"
Nillumbik Shire,,Amenity Tree Local Law + overlays,"Permit generally required for larger amenity trees; exemptions for dead/weeds/pine and bushfire areas per council",,, "https://www.nillumbik.vic.gov.au/"
Northern Grampians Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.ngshire.vic.gov.au/Develop-and-Build/Planning"
Port Phillip City,,Significant Tree Local Law/Register,"Permit required for significant trees meeting size criteria; planning overlays may also apply",,, "https://www.portphillip.vic.gov.au/"
Pyrenees Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.pyrenees.vic.gov.au/Build-Develop/Planning-Permits"
Queenscliffe Borough,,Local permit guidance,"Guidance on permits and tree removal on private property; check overlays",,, "https://www.queenscliffe.vic.gov.au/build-and-develop/planning-permits#privateProperty"
South Gippsland Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.southgippsland.vic.gov.au/planning_permits"
Southern Grampians Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.sthgrampians.vic.gov.au/Page/Page.aspx?Page_Id=1444"
Stonnington City,,Significant Tree Local Law,"Significant trees (size thresholds) need a permit to prune/remove; planning overlays may also apply",,, "https://www.stonnington.vic.gov.au/"
Strathbogie Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.strathbogie.vic.gov.au/build-and-develop/planning-permits/"
Surf Coast Shire,,Overlays + native vegetation,"Permit may be required for vegetation removal (e.g., VPO/ESO/HO areas)",,, "https://www.surfcoast.vic.gov.au/"
Swan Hill Rural City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.swanhill.vic.gov.au/resident-services/planning-building/planning/"
Towong Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.towong.vic.gov.au/Plan-and-Build/Planning/Planning-Forms-and-Fees"
Wangaratta Rural City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.wangaratta.vic.gov.au/Develop/Planning/Do-I-need-a-planning-permit"
Warrnambool City,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.warrnambool.vic.gov.au/planning-permits"
Wellington Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.wellington.vic.gov.au/plan-and-build/planning/permits"
West Wimmera Shire,,,Native vegetation (Clause 52.17) may require a planning permit,,,,"https://www.westwimmera.vic.gov.au/planning"
Whitehorse City,,Check Council Website,Check Council Website,Check Council Website,, "https://www.whitehorse.vic.gov.au/planning-and-building"
Whittlesea City,,Check Council Website,Check Council Website,Check Council Website,, "https://www.whittlesea.vic.gov.au/building-planning"
Wodonga City,,,Planning permit may be required (see Planning → Apply for a planning permit),,,,"https://www.wodonga.vic.gov.au/Building-Planning"
Wyndham City,,,Native vegetation removal on council/private land is regulated; planning permits may be required,,,,"https://www.wyndham.vic.gov.au/services/building-planning/do-i-need-approval/planning-frequently-asked-questions"
Yarra City,,Significant Tree Local Law/Register,"Permit required for trees meeting significant size (e.g., ≥40cm diameter) and for works within TPZ; overlays may also apply",,, "https://www.yarracity.vic.gov.au/"
Yarra Ranges Shire,,Private tree guidance,"Some removals near buildings exempt; planning overlays may apply",,, "https://www.yarraranges.vic.gov.au/Develop/Planning-and-building/Planning/Tree-removal-on-private-property"
Yarriambiack Shire,,Local laws,"Local law permits may be required for works/vegetation on nature strips and related activities; check planning for vegetation",,, "https://yarriambiack.vic.gov.au/our-council/local-laws/"
''';

  static List<Map<String, dynamic>> _councilDataList = [];

  /// Initialize the council data
  static void initialize() {
    if (_councilDataList.isEmpty) {
      final lines = _councilData.trim().split('\n');
      final headers = lines[0].split(',');
      
      for (int i = 1; i < lines.length; i++) {
        final values = lines[i].split(',');
        if (values.length >= headers.length) {
          final council = <String, dynamic>{};
          for (int j = 0; j < headers.length; j++) {
            council[headers[j].trim()] = values[j].trim();
          }
          _councilDataList.add(council);
        }
      }
    }
  }

  /// Get council data by council name
  static Map<String, dynamic>? getCouncilData(String councilName) {
    initialize();
    
    // Try exact match first
    for (final council in _councilDataList) {
      if (council['Council']?.toLowerCase() == councilName.toLowerCase()) {
        return council;
      }
    }
    
    // Try partial match
    for (final council in _councilDataList) {
      if (council['Council']?.toLowerCase().contains(councilName.toLowerCase()) == true) {
        return council;
      }
    }
    
    return null;
  }

  /// Get all council data
  static List<Map<String, dynamic>> getAllCouncilData() {
    initialize();
    return List.from(_councilDataList);
  }

  /// Search councils by keyword
  static List<Map<String, dynamic>> searchCouncils(String keyword) {
    initialize();
    final results = <Map<String, dynamic>>[];
    
    for (final council in _councilDataList) {
      final councilName = council['Council']?.toLowerCase() ?? '';
      final purpose = council['Purpose']?.toLowerCase() ?? '';
      final removalTrigger = council['RemovalTrigger']?.toLowerCase() ?? '';
      
      if (councilName.contains(keyword.toLowerCase()) ||
          purpose.contains(keyword.toLowerCase()) ||
          removalTrigger.contains(keyword.toLowerCase())) {
        results.add(council);
      }
    }
    
    return results;
  }

  /// Get councils with specific overlay types
  static List<Map<String, dynamic>> getCouncilsWithOverlays() {
    initialize();
    return _councilDataList.where((council) {
      final overlay = council['OverlaySchedule']?.toString().toLowerCase() ?? '';
      return overlay.isNotEmpty && overlay != 'check council website';
    }).toList();
  }

  /// Get councils with local laws
  static List<Map<String, dynamic>> getCouncilsWithLocalLaws() {
    initialize();
    return _councilDataList.where((council) {
      final purpose = council['Purpose']?.toString().toLowerCase() ?? '';
      return purpose.contains('local law') || purpose.contains('local laws');
    }).toList();
  }

  /// Get councils requiring permits for native vegetation
  static List<Map<String, dynamic>> getCouncilsRequiringNativeVegetationPermits() {
    initialize();
    return _councilDataList.where((council) {
      final removalTrigger = council['RemovalTrigger']?.toString().toLowerCase() ?? '';
      return removalTrigger.contains('clause 52.17') || removalTrigger.contains('native vegetation');
    }).toList();
  }
}
