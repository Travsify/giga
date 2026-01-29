import 'package:dio/dio.dart';

class AddressSearchService {
  final String _apiKey = 'AIzaSyDVqP4CjWp_fcFim7d_E0kAL35Ie2gWMzE';
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> getSuggestions(String input) async {
    if (input.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'types': 'address',
          'components': 'country:gb|country:ng|country:gh', // Limit to current markets
        },
      );

      if (response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => {
          'description': p['description'],
          'place_id': p['place_id'],
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
