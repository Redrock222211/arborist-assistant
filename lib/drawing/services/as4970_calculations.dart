import 'dart:math' as math;

/// AS 4970-2009 formulas for SRZ and TPZ.
/// DBH must be in centimeters.
class As4970Calculations {
  /// Tree Protection Zone radius (TPZ) in meters
  /// TPZ radius = DBH(cm) × 12 × 0.01 = DBH × 0.12
  /// Minimum 2 m, maximum 15 m (typical practice; adjust if your policy differs)
  static double tpzRadiusMeters(double dbhCm) {
    final r = dbhCm * 0.12;
    if (r.isNaN) return 0.0;
    return r.clamp(2.0, 15.0);
  }

  /// Structural Root Zone radius (SRZ) in meters
  /// SRZ radius = (D × 50)^0.42 × 0.64, where D is trunk diameter in meters.
  /// Convert DBH from cm to meters first.
  static double srzRadiusMeters(double dbhCm) {
    final dMeters = dbhCm / 100.0;
    if (dMeters <= 0) return 0.0;
    final base = dMeters * 50.0;
    final radius = math.pow(base, 0.42) * 0.64;
    return radius.toDouble();
  }
}


