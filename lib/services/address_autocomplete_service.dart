import 'package:geocoding/geocoding.dart';

class AddressAutocompleteService {
  static List<Placemark> _recentSearches = [];
  static const int _maxRecentSearches = 10;

  // Comprehensive list of Melbourne and Victoria addresses for reliable autocomplete
  static const List<String> _sampleAddresses = [
    // Melbourne CBD
    '123 Collins Street, Melbourne VIC 3000',
    '456 Bourke Street, Melbourne VIC 3000',
    '789 Swanston Street, Melbourne VIC 3000',
    '321 Flinders Street, Melbourne VIC 3000',
    '654 Elizabeth Street, Melbourne VIC 3000',
    '987 Little Collins Street, Melbourne VIC 3000',
    '147 Russell Street, Melbourne VIC 3000',
    '258 Exhibition Street, Melbourne VIC 3000',
    '369 Spring Street, Melbourne VIC 3000',
    '741 Lonsdale Street, Melbourne VIC 3000',
    '852 Queen Street, Melbourne VIC 3000',
    '963 Victoria Street, Melbourne VIC 3000',
    
    // Fitzroy
    '159 Gertrude Street, Fitzroy VIC 3065',
    '357 Brunswick Street, Fitzroy VIC 3065',
    '468 Smith Street, Collingwood VIC 3066',
    '579 Johnston Street, Collingwood VIC 3066',
    
    // Northcote
    '681 High Street, Northcote VIC 3070',
    '792 St Georges Road, Northcote VIC 3070',
    
    // Carlton
    '813 Lygon Street, Carlton VIC 3053',
    '924 Rathdowne Street, Carlton VIC 3053',
    
    // South Yarra
    '135 Toorak Road, South Yarra VIC 3141',
    '246 Domain Road, South Yarra VIC 3141',
    
    // St Kilda
    '357 Acland Street, St Kilda VIC 3182',
    '468 St Kilda Road, St Kilda VIC 3182',
    
    // Richmond
    '579 Bridge Road, Richmond VIC 3121',
    '681 Swan Street, Richmond VIC 3121',
    
    // Prahran
    '792 Chapel Street, Prahran VIC 3181',
    '813 High Street, Prahran VIC 3181',
    
    // Windsor
    '924 Chapel Street, Windsor VIC 3181',
    '135 High Street, Windsor VIC 3181',
    
    // South Melbourne
    '246 Clarendon Street, South Melbourne VIC 3205',
    '357 Park Street, South Melbourne VIC 3205',
    
    // Port Melbourne
    '468 Bay Street, Port Melbourne VIC 3207',
    '579 Graham Street, Port Melbourne VIC 3207',
    
    // Albert Park
    '681 Victoria Avenue, Albert Park VIC 3206',
    '792 Bridport Street, Albert Park VIC 3206',
    
    // Middle Park
    '813 Richardson Street, Middle Park VIC 3206',
    '924 Canterbury Road, Middle Park VIC 3206',
    
    // West Melbourne
    '135 Spencer Street, West Melbourne VIC 3003',
    '246 Dudley Street, West Melbourne VIC 3003',
    
    // North Melbourne
    '357 Errol Street, North Melbourne VIC 3051',
    '468 Queensberry Street, North Melbourne VIC 3051',
    
    // East Melbourne
    '579 Albert Street, East Melbourne VIC 3002',
    '681 Victoria Parade, East Melbourne VIC 3002',
    
    // Docklands
    '792 Harbour Esplanade, Docklands VIC 3008',
    '813 Waterfront Way, Docklands VIC 3008',
    
    // Geelong
    '123 Moorabool Street, Geelong VIC 3220',
    '456 Malop Street, Geelong VIC 3220',
    '789 Ryrie Street, Geelong VIC 3220',
    '321 Yarra Street, Geelong VIC 3220',
    
    // Ballarat
    '654 Sturt Street, Ballarat VIC 3350',
    '987 Lydiard Street, Ballarat VIC 3350',
    '147 Armstrong Street, Ballarat VIC 3350',
    
    // Bendigo
    '258 Hargreaves Street, Bendigo VIC 3550',
    '369 View Street, Bendigo VIC 3550',
    '741 Mitchell Street, Bendigo VIC 3550',
  ];

  /// Get address suggestions based on user input
  static Future<List<String>> getAddressSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      List<String> suggestions = [];
      final lowerQuery = query.toLowerCase().trim();
      
      // First, try to get suggestions from our predefined list
      for (String address in _sampleAddresses) {
        if (address.toLowerCase().contains(lowerQuery)) {
          suggestions.add(address);
          if (suggestions.length >= 15) break; // Increased limit for better coverage
        }
      }
      
      // Also try to get suggestions from recent searches
      for (Placemark place in _recentSearches) {
        String formattedAddress = formatAddress(place);
        if (formattedAddress.toLowerCase().contains(lowerQuery) && 
            !suggestions.contains(formattedAddress)) {
          suggestions.add(formattedAddress);
          if (suggestions.length >= 20) break; // Increased total limit
        }
      }
      
      // If we have very few suggestions, try to add some generic ones
      if (suggestions.length < 5) {
        if (lowerQuery.contains('melbourne')) {
          suggestions.addAll([
            'Collins Street, Melbourne VIC 3000',
            'Bourke Street, Melbourne VIC 3000',
            'Swanston Street, Melbourne VIC 3000',
            'Flinders Street, Melbourne VIC 3000',
            'Elizabeth Street, Melbourne VIC 3000',
          ]);
        } else if (lowerQuery.contains('street')) {
          suggestions.addAll([
            'Collins Street, Melbourne VIC 3000',
            'Bourke Street, Melbourne VIC 3000',
            'Swanston Street, Melbourne VIC 3000',
            'Flinders Street, Melbourne VIC 3000',
            'Elizabeth Street, Melbourne VIC 3000',
          ]);
        } else if (lowerQuery.contains('collins')) {
          suggestions.addAll([
            'Collins Street, Melbourne VIC 3000',
            'Little Collins Street, Melbourne VIC 3000',
          ]);
        } else if (lowerQuery.contains('bourke')) {
          suggestions.addAll([
            'Bourke Street, Melbourne VIC 3000',
            'Little Bourke Street, Melbourne VIC 3000',
          ]);
        }
      }
      
      // Remove duplicates and return
      return suggestions.toSet().take(20).toList();
      
    } catch (e) {
      print('Error getting address suggestions: $e');
      // Fallback to basic filtering
      final lowerQuery = query.toLowerCase();
      return _sampleAddresses
          .where((address) => address.toLowerCase().contains(lowerQuery))
          .take(15)
          .toList();
    }
  }

  /// Get current location and format as address
  static Future<String?> getCurrentLocationAddress() async {
    try {
      // This would typically use geolocator to get current position
      // For now, we'll return null and handle this in the UI
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Format a placemark into a readable address string
  static String formatAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.add(place.subThoroughfare!);
    }
    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      parts.add(place.thoroughfare!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }
    
    return parts.join(', ');
  }

  /// Get address from coordinates (reverse geocoding)
  static Future<List<Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return [];
    }
  }

  /// Get coordinates for an address string
  static Future<Map<String, double>?> getCoordinatesForAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations[0].latitude,
          'longitude': locations[0].longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error getting coordinates for address: $e');
      return null;
    }
  }

  /// Add a search to recent searches
  static void addToRecentSearches(Placemark placemark) {
    _recentSearches.removeWhere((p) =>
      p.street == placemark.street &&
      p.locality == placemark.locality
    );
    _recentSearches.insert(0, placemark);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.take(_maxRecentSearches).toList();
    }
  }

  /// Get recent searches
  static List<String> getRecentSearches() {
    return _recentSearches.map((p) => formatAddress(p)).toList();
  }
}

