/// Planning domain types for Vicmap Planning API integration
/// These types conform to the existing app architecture and provide
/// structured data for planning overlays, zones, and ordinance information.

/// Result of planning lookup containing scheme, LGA, zone and overlay information
class PlanningResult {
  final String scheme;
  final String lga;
  final ZoneResult? zone;
  final List<ZoneResult> zones;
  final List<OverlayResult> overlays;
  final DateTime timestamp;
  final String? error;

  const PlanningResult({
    required this.scheme,
    required this.lga,
    this.zone,
    required this.zones,
    required this.overlays,
    required this.timestamp,
    this.error,
  });

  /// Create from JSON map
  factory PlanningResult.fromJson(Map<String, dynamic> json) {
    return PlanningResult(
      scheme: json['scheme'] ?? '',
      lga: json['lga'] ?? '',
      zone: json['zone'] != null ? ZoneResult.fromJson(json['zone']) : null,
      zones: (json['zones'] as List<dynamic>?)
          ?.map((e) => ZoneResult.fromJson(e))
          .toList() ?? [],
      overlays: (json['overlays'] as List<dynamic>?)
          ?.map((e) => OverlayResult.fromJson(e))
          .toList() ?? [],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      error: json['error'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'scheme': scheme,
      'lga': lga,
      'zone': zone?.toJson(),
      'zones': zones.map((e) => e.toJson()).toList(),
      'overlays': overlays.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      if (error != null) 'error': error,
    };
  }

  /// Check if the result has an error
  bool get hasError => error != null;

  /// Check if the result has planning data
  bool get hasData => !hasError && (zone != null || zones.isNotEmpty || overlays.isNotEmpty);
}

/// Zone information from planning scheme
class ZoneResult {
  final String code;
  final String? number;
  final String? status;
  final String? vppUrl;
  final String? localPolicyUrl;
  final String? description;
  final String? zoneType;

  const ZoneResult({
    required this.code,
    this.number,
    this.status,
    this.vppUrl,
    this.localPolicyUrl,
    this.description,
    this.zoneType,
  });

  /// Create from JSON map
  factory ZoneResult.fromJson(Map<String, dynamic> json) {
    return ZoneResult(
      code: json['code'] ?? '',
      number: json['number'],
      status: json['status'],
      vppUrl: json['vppUrl'],
      localPolicyUrl: json['localPolicyUrl'],
      description: json['description'],
      zoneType: json['zoneType'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      if (number != null) 'number': number,
      if (status != null) 'status': status,
      if (vppUrl != null) 'vppUrl': vppUrl,
      if (localPolicyUrl != null) 'localPolicyUrl': localPolicyUrl,
      if (description != null) 'description': description,
      if (zoneType != null) 'zoneType': zoneType,
    };
  }
}

/// Overlay information from planning scheme
class OverlayResult {
  final String code;
  final String description;
  final String? vppUrl;
  final String? localPolicyUrl;
  final Map<String, String>? permitRequirements;

  const OverlayResult({
    required this.code,
    required this.description,
    this.vppUrl,
    this.localPolicyUrl,
    this.permitRequirements,
  });

  /// Create from JSON map
  factory OverlayResult.fromJson(Map<String, dynamic> json) {
    return OverlayResult(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      vppUrl: json['vppUrl'],
      localPolicyUrl: json['localPolicyUrl'],
      permitRequirements: json['permitRequirements'] != null 
          ? Map<String, String>.from(json['permitRequirements'])
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      if (vppUrl != null) 'vppUrl': vppUrl,
      if (localPolicyUrl != null) 'localPolicyUrl': localPolicyUrl,
      if (permitRequirements != null) 'permitRequirements': permitRequirements,
    };
  }
}

/// ArcGIS feature response structure
class ArcGISFeature {
  final Map<String, dynamic> attributes;
  final Map<String, dynamic>? geometry;

  const ArcGISFeature({
    required this.attributes,
    this.geometry,
  });

  /// Create from JSON map
  factory ArcGISFeature.fromJson(Map<String, dynamic> json) {
    return ArcGISFeature(
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      geometry: json['geometry'] != null 
          ? Map<String, dynamic>.from(json['geometry']) 
          : null,
    );
  }
}

/// ArcGIS query response structure
class ArcGISResponse {
  final List<ArcGISFeature> features;
  final bool exceededTransferLimit;

  const ArcGISResponse({
    required this.features,
    required this.exceededTransferLimit,
  });

  /// Create from JSON map
  factory ArcGISResponse.fromJson(Map<String, dynamic> json) {
    return ArcGISResponse(
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => ArcGISFeature.fromJson(e))
          .toList() ?? [],
      exceededTransferLimit: json['exceededTransferLimit'] ?? false,
    );
  }
}
