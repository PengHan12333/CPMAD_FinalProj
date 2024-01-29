import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:location/location.dart';

import '../ordering/orderpage.dart';

class RestaurantExplorer extends StatefulWidget {
  @override
  _RestaurantExplorerState createState() => _RestaurantExplorerState();
}

class _RestaurantExplorerState extends State<RestaurantExplorer> {
  Completer<GoogleMapController> _controller = Completer();
  LocationData _userLocation;
  Set<Marker> _restaurantMarkers = Set<Marker>();
  places.GoogleMapsPlaces _placesService;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _controller.future.then((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    try {
      Location location = Location();
      _userLocation = await location.getLocation();
      _placesService = places.GoogleMapsPlaces(
          apiKey:
              'AIzaSyAhiBXtLEo2VeYpXAV1CrjftTdFweeYi6Q'); // Replace with your API key
      _initMap();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  void _initMap() {
    if (_userLocation != null) {
      _updateRestaurantMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userLocation == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              mapType: MapType.terrain,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _userLocation.latitude,
                  _userLocation.longitude,
                ),
                zoom: 15,
              ),
              markers: _restaurantMarkers,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _updateRestaurantMarkers();
              },
            ),
    );
  }

  Future<void> _updateRestaurantMarkers() async {
    // Use Google Places API to get nearby restaurants
    places.PlacesSearchResponse response =
        await _placesService.searchNearbyWithRadius(
      places.Location(_userLocation.latitude, _userLocation.longitude),
      900, // Fixed radius of 2000 meters
      type: 'restaurant',
    );

    // Clear existing markers
    _restaurantMarkers.clear();

    // Add new markers for the first four nearby restaurants
    int count = 0;
    for (places.PlacesSearchResult result in response.results) {
      if (count < 4) {
        _restaurantMarkers.add(Marker(
          markerId: MarkerId(result.placeId),
          position: LatLng(
              result.geometry.location.lat, result.geometry.location.lng),
          infoWindow: InfoWindow(title: result.name),
          onTap: () => _showRestaurantDetails(context, result),
        ));
        count++;
      } else {
        break; // Stop adding markers once we reach the limit
      }
    }
    // Force a rebuild to update the markers on the map
    if (mounted) {
      setState(() {});
    }
  }

  void _showRestaurantDetails(
      BuildContext context, places.PlacesSearchResult result) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 120.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 70.0,
                width: 70.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                      result.photos != null && result.photos.isNotEmpty
                          ? _buildPhotoUrl(result.photos[0].photoReference)
                          : 'https://via.placeholder.com/100',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      result.name,
                      style: GoogleFonts.nunito(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (result.openingHours != null)
                          Icon(
                            result.openingHours.openNow == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: result.openingHours.openNow == true
                                ? Colors.green
                                : Colors.red,
                          )
                        else
                          Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        SizedBox(width: 4.0),
                        Text(
                          'Status: ${result.openingHours?.openNow == true ? 'Open' : 'Closed'}',
                          style: GoogleFonts.roboto(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star_sharp,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          'Rating: ${result.rating ?? 'N/A'}',
                          style: GoogleFonts.roboto(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: result.openingHours?.openNow ?? false
                    ? () async {
                        // Add functionality for the "Visit" button
                        // Convert the rating to a String before passing to OrderPage
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderPage(
                              restaurantData: {
                                'name': result.name ?? 'N/A',
                                'rating': result.rating?.toString() ?? 'N/A',
                                'image': result.photos != null &&
                                        result.photos.isNotEmpty
                                    ? _buildPhotoUrl(
                                        result.photos[0].photoReference)
                                    : 'https://via.placeholder.com/100',
                                'location': result.vicinity ?? 'N/A',
                                // Add other properties as needed
                              },
                            ),
                          ),
                        );
                      }
                    : null, // Set onPressed to null to disable the button
                icon: Icon(Icons.remove_red_eye_sharp, size: 18),
                label: Text(
                  'View',
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Helper function to build photo URL
  String _buildPhotoUrl(String photoReference) {
    final String apiKey =
        'AIzaSyAhiBXtLEo2VeYpXAV1CrjftTdFweeYi6Q'; // Replace with your API key
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
  }
}
