import 'dart:convert';
import 'package:http/http.dart' as http;

class WebGeocodingService {
  // Nominatim forward geocoding (address -> lat/lon)
  static Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(address)}&format=json&addressdetails=1&limit=1',
      );
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'ArboristAssistant/1.0 (web geocoding)'
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return {
              'latitude': lat,
              'longitude': lon,
            };
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Nominatim reverse geocoding (lat/lon -> address string)
  static Future<String?> reverseGeocodeToAddress(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'ArboristAssistant/1.0 (web geocoding)'
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final display = data['display_name']?.toString();
        return display;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
