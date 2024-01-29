import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class DataService {
  final String apiKey; // Your Google Places API key

  DataService(this.apiKey);

  Future<List<Map<String, dynamic>>> getRestaurantsNearUser(
      double userLatitude, double userLongitude) async {
    final String baseUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    final String location = '$userLatitude,$userLongitude';
    final String radius =
        '5000'; // Adjust the radius based on your requirements
    final String type = 'restaurant';
    final String url =
        '$baseUrl?location=$location&radius=$radius&type=$type&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          final List<Map<String, dynamic>> restaurantsWithStatus = [];

          for (final result in results) {
            final List<dynamic> photos = result['photos'] ?? [];
            final String photoReference = _getMainPhotoReference(photos);
            final String photoUrl = _buildPhotoUrl(photoReference);

            restaurantsWithStatus.add({
              'placeId': result['place_id'],
              'name': result['name'],
              'location': result['vicinity'],
              'status': result['business_status'], // Include the status
              'rating': result['rating'],
              'image': photoUrl,
              // Add more fields as needed
            });
          }

          return restaurantsWithStatus;
        } else {
          throw Exception(
              'Error: ${data['status']} - ${data['error_message']}');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getTodaysDeals() async {
    final List<Map<String, dynamic>> allRestaurants =
        await getRestaurantsNearUser(
            1.3521, 103.8198); // Example coordinates for Singapore
    return _getRandomRestaurants(allRestaurants, 4);
  }

  Future<List<Map<String, dynamic>>> getPopularEateries() async {
    final List<Map<String, dynamic>> allRestaurants =
        await getRestaurantsNearUser(
            1.3521, 103.8198); // Example coordinates for Singapore
    return _getRandomRestaurants(
        allRestaurants, 4); // Adjust the count to get the next 5 restaurants
  }

  List<Map<String, dynamic>> _getRandomRestaurants(
      List<Map<String, dynamic>> allRestaurants, int count) {
    final random = Random();
    final List<Map<String, dynamic>> randomRestaurants = [];

    if (allRestaurants.length <= count) {
      return allRestaurants;
    }

    while (randomRestaurants.length < count) {
      final randomIndex = random.nextInt(allRestaurants.length);
      final randomRestaurant = allRestaurants[randomIndex];
      if (!randomRestaurants.contains(randomRestaurant)) {
        randomRestaurants.add(randomRestaurant);
      }
    }

    return randomRestaurants;
  }

  String _buildPhotoUrl(String photoReference) {
    if (photoReference == null) {
      return ''; // Return an empty string or a default image URL if no reference is available
    }

    final String baseUrl = 'https://maps.googleapis.com/maps/api/place/photo';
    final int maxWidth = 400; // Adjust the size based on your requirements

    return '$baseUrl?maxwidth=$maxWidth&photoreference=$photoReference&key=$apiKey';
    // Replace 'YOUR_API_KEY' with your actual Google Places API key
  }

  String _getMainPhotoReference(List<dynamic> photos) {
    // Iterate through the list of photos to find the main photo
    for (final photo in photos) {
      if (photo['width'] >= 400) {
        return photo['photo_reference'];
      }
    }
    // If no main photo is found, return the first photo reference
    return photos.isNotEmpty ? photos[0]['photo_reference'] : null;
  }
}
