import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_webservice/places.dart';

import '../../models/user.dart';
import '../../services/authentication_service.dart';
import '../../services/home_data_service.dart';
import '../auth/LoginPage.dart';
import '../discounts/LoyaltyPage.dart';
import '../ordering/orderpage.dart';
import '../profile/AboutUsPage.dart';
import '../profile/ProfilePage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DataService dataService =
      DataService('AIzaSyAhiBXtLEo2VeYpXAV1CrjftTdFweeYi6Q');
  final placesApiClient =
      GoogleMapsPlaces(apiKey: 'AIzaSyAhiBXtLEo2VeYpXAV1CrjftTdFweeYi6Q');
  // Add a TextEditingController for the search input
  final TextEditingController _searchController = TextEditingController();
  // Use a StreamController to update the search results in real-time
  final _searchResultsController = StreamController<List<Prediction>>();
  bool isSearching = false;
  bool isPositionedVisible = true; // Initial value, adjust as needed

  // Helper function to build photo URL
  String _buildPhotoUrl(String photoReference) {
    final String apiKey =
        'AIzaSyAhiBXtLEo2VeYpXAV1CrjftTdFweeYi6Q'; // Replace with your API key
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
  }

// Callback when search text changes
  void _onSearchTextChanged(String query) async {
    if (query.isEmpty && _searchController.text.isEmpty) {
      _searchResultsController.add([]);
      return;
    }

    try {
      // Use the Places API to get real-time search predictions
      final response = await placesApiClient.autocomplete(query,
          language: 'en',
          types: [
            'restaurant'
          ],
          components: [
            Component(Component.country, "SG")
          ]); // Bias towards Singapore

      if (response.isOkay) {
        final predictions = response.predictions;
        _searchResultsController.add(predictions);
      } else {
        // Handle API error - log or provide user feedback
        print('Places API Error: ${response.errorMessage}');
        _searchResultsController.add([]);
      }
    } catch (error) {
      // Handle general error - log or provide user feedback
      print('Error: $error');
      _searchResultsController.add([]);
    }
  }

  @override
  void dispose() {
    _searchResultsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        searchController: _searchController,
        onSearchTextChanged: _onSearchTextChanged,
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 70),
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDiscountsSection(),
                    SizedBox(height: 2.0),
                    _buildSectionTitle(
                      'Today\'s Specials',
                      subtitle: 'Explore exclusive offers for today!',
                      fontSize: 24.0,
                    ),
                    _buildHorizontalList(() => dataService.getTodaysDeals(),
                        isTodayDealData: true),
                    SizedBox(height: 2.0),
                    _buildSectionTitle(
                      'Near You',
                      subtitle: 'Discover popular eateries near your location!',
                      fontSize: 24.0,
                    ),
                    _buildHorizontalList(() => dataService.getPopularEateries(),
                        isTodayDealData: false),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: kToolbarHeight - 50.0,
            left: 0,
            right: 0,
            child: StreamBuilder<List<Prediction>>(
              stream: _searchResultsController.stream,
              builder: (context, snapshot) {
                if (_searchController.text.isEmpty) {
                  return Container(); // Return an empty container if search text is empty
                } else if (snapshot.hasData && snapshot.data.isNotEmpty) {
                  return Container(
                    height: 180.0,
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.6),
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 10),
                                Flexible(
                                  // Replaced Expanded with Flexible
                                  child: Text(
                                    snapshot.data[index].structuredFormatting
                                        .mainText,
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              _onSuggestionSelected(snapshot.data[index]);

                              // Retrieve additional details using Place Details API
                              final PlacesDetailsResponse detailsResponse =
                                  await placesApiClient.getDetailsByPlaceId(
                                      snapshot.data[index].placeId);

                              // Check if the details response is successful
                              if (detailsResponse.isOkay) {
                                // Accessing specific properties from the details response
                                String name = detailsResponse.result.name;
                                String rating =
                                    detailsResponse.result.rating?.toString() ??
                                        'N/A';
                                String image = detailsResponse
                                        .result.photos.isNotEmpty
                                    ? _buildPhotoUrl(detailsResponse
                                        .result.photos[0].photoReference)
                                    : 'https://via.placeholder.com/100'; // Fixed the syntax here
                                String location =
                                    detailsResponse.result.formattedAddress;

                                // Pass the details to the OrderPage
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderPage(
                                      restaurantData: {
                                        'name': name,
                                        'rating': rating.toString(),
                                        'image': image,
                                        'location': location,
                                        // Add other properties as needed
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                // Handle API error - log or provide user feedback
                                print(
                                    'Place Details API Error: ${detailsResponse.errorMessage}');
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSuggestionSelected(Prediction prediction) {
    // Handle the selected suggestion
    print('Selected Suggestion: ${prediction.description}');
    // You can use the prediction.placeId to get detailed information if needed
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: FutureBuilder<MyUser>(
        future: AuthenticationService().getCurrentUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            MyUser user = snapshot.data;
            print('FutureBuilder - User: $user');

            // Assuming user.photoURL is the URL of the image you want to clear from the cache
            String imageUrl = user?.photoURL;

            // Clear the cache for the specified image URL
            CachedNetworkImageProvider(imageUrl).evict();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.grey[900]],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                          user?.photoURL?.isNotEmpty == true
                              ? user.photoURL
                              : 'https://placekitten.com/100/100',
                        ),
                        radius: 30.0,
                      ),
                      SizedBox(height: 18.0),
                      Text(
                        user?.fullName ?? 'John Doe',
                        style: GoogleFonts.raleway(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Text(
                        user?.email ?? 'john.doe@example.com',
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.black),
                  title: Text(
                    'Profile',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(color: Colors.black),
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.black),
                  title: Text(
                    'About Us',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(color: Colors.black),
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AboutUsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.black),
                  title: Text(
                    'Sign Out',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(color: Colors.black),
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () async {
                    await AuthenticationService().signOut();
                    // Add a print statement to check if the sign-out is successful
                    print('User signed out');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String subtitle,
    double fontSize = 24.0,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (_, double opacity, __) {
          return Opacity(
            opacity: opacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    textStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList(
      Future<List<Map<String, dynamic>>> Function() dataFuture,
      {bool isTodayDealData = false}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dataFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data.isEmpty) {
          return Center(child: Text('No data available.'));
        } else {
          return Container(
            height: 260.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final item = snapshot.data[index];
                return SizedBox(
                  width: 240.0,
                  child: _buildRestaurantCard(item, isTodayDealData),
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildDiscountsSection() {
    return Container(
      height: 170.0,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/discount_bg.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exclusive Discounts',
                  style: GoogleFonts.quicksand(
                    textStyle: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 14.0),
                Text(
                  'Save big with our limited-time offers!',
                  style: GoogleFonts.quicksand(
                    textStyle: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 28.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoyaltyProgramPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue[900],
                  ),
                  child: Text(
                    'View Discounts',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(
      Map<String, dynamic> restaurant, bool isTodayDealData) {
    bool isClosed =
        (restaurant['status']?.toUpperCase() ?? '').contains('CLOSED');
    bool isPromo = isTodayDealData;

    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () async {
          // Convert the rating to a String before passing to OrderPage
          if (isClosed != true) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderPage(
                  restaurantData: {
                    'name': restaurant['name'],
                    'rating':
                        restaurant['rating'].toString(), // Convert to String
                    'image': restaurant['image'],
                    'location': restaurant['location']
                    // Add other properties as needed
                  },
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: Offset(2, 2),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(restaurant['image'] ?? ''),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print('Error loading image: $exception');
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? 'No Name',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 7.0),
                  Row(
                    children: [
                      Text(
                        'Rating: ${restaurant['rating'] ?? 'N/A'}',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16.0,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isClosed ? Colors.red[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${restaurant['status'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: isClosed
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 7,
                      ),
                      if (isPromo)
                        Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            'HOT',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearchTextChanged;

  SearchAppBar({
    this.searchController,
    this.onSearchTextChanged,
  });

  @override
  _SearchAppBarState createState() => _SearchAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  bool isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[100],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: Builder(
        builder: (BuildContext context) {
          return InkWell(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Icon(Icons.menu_sharp, color: Colors.black),
          );
        },
      ),
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _searchFocusNode,
                    controller: widget.searchController,
                    onChanged: (query) {
                      setState(() {
                        isSearching = query.isNotEmpty;
                      });
                      widget.onSearchTextChanged(query);
                    },
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(left: 20),
                      hintText: 'Search for restaurants...',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: isSearching
                      ? Icon(Icons.clear, color: Colors.grey)
                      : Icon(Icons.search, color: Colors.grey),
                  onPressed: () {
                    if (isSearching) {
                      setState(() {
                        widget.searchController.clear();
                        widget.onSearchTextChanged('');
                        isSearching = false;
                      });
                    } else {
                      // Perform search or open place picker as needed
                      // _openPlacePicker();
                      _searchFocusNode
                          .requestFocus(); // Set focus on search field
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
