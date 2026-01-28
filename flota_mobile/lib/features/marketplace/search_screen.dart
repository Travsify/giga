import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Timer? _debounce;
  final String _googleApiKey = 'AIzaSyDVqP4CjWp_fcFim7d_E0kAL35Ie2gWMzE'; // From AndroidManifest
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _sessionToken = _generateUuid();
  }

  String _generateUuid() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPlaces(query);
    });
  }

  Future<void> _fetchPlaces(String query) async {
    final countryCode = ref.read(authProvider).countryCode?.toLowerCase() ?? 'gb';
    
    // Components filtering: country:uk|country:ng etc.
    // Mapping our country codes to Google's ISO 3166-1 Alpha-2
    // 'GB' -> 'uk' for Google Components (though 'gb' usually works, 'uk' is safer for google services sometimes, but standard is GB)
    // Actually, Google Places uses ISO 3166-1 Alpha-2. 'GB' is correct. 'NG' is correct.
    
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&key=$_googleApiKey'
        '&sessiontoken=$_sessionToken'
        '&components=country:$countryCode'; 

    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        if (response.data['status'] == 'OK') {
             final predictions = response.data['predictions'] as List;
             setState(() {
               _results = predictions.map((p) => {
                 'description': p['description'],
                 'place_id': p['place_id'],
                 'main_text': p['structured_formatting']['main_text'] ?? p['description'],
                 'secondary_text': p['structured_formatting']['secondary_text'] ?? '',
               }).toList();
             });
        } else {
             // Handle ZERO_RESULTS or errors gracefully
             debugPrint('Google Places Status: ${response.data['status']}');
             if (response.data['status'] == 'ZERO_RESULTS') {
                 setState(() => _results = []);
             }
        }
      }
    } catch (e) {
      debugPrint('Google Places Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: AppTheme.primaryBlue,
          decoration: InputDecoration(
            hintText: 'Search address or location...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 18), 
          onChanged: _onSearch,
        ),
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   if (_searchController.text.isNotEmpty && _searchController.text.length > 2)
                     const Padding(
                       padding: EdgeInsets.all(20.0),
                       child: CircularProgressIndicator(),
                     )
                   else ...[
                     Icon(Icons.location_on_outlined, size: 80, color: Colors.grey[200]),
                     const SizedBox(height: 10),
                     Text('Start typing to find location', style: TextStyle(color: Colors.grey[500])),
                   ]
                ],
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final place = _results[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue),
                  title: Text(place['main_text'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(place['secondary_text']),
                  onTap: () async {
                    // Fetch Place Details (Lat/Lng)
                    final placeId = place['place_id'];
                    final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey&sessiontoken=$_sessionToken';
                    
                    try {
                      final response = await Dio().get(detailsUrl);
                      if (response.statusCode == 200 && response.data['status'] == 'OK') {
                        final location = response.data['result']['geometry']['location'];
                        final lat = location['lat'];
                        final lng = location['lng'];
                        
                        // Return full result
                        if (context.mounted) {
                          context.pop({
                            'address': place['description'],
                            'place_id': placeId,
                            'lat': lat,
                            'lng': lng,
                          });
                        }
                      }
                    } catch (e) {
                      debugPrint('Error fetching details: $e');
                      // Fallback: return just address if details fail
                      if (context.mounted) {
                        context.pop({
                          'address': place['description'],
                          'place_id': placeId,
                        });
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
