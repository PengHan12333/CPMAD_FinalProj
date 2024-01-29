import 'dart:math';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../restaurant/CartPage.dart';
import '../restaurant/Menu_Data.dart';

class OrderPage extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  OrderPage({this.restaurantData});
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Access the restaurantData directly from widget
  Map<String, dynamic> get restaurantData => widget.restaurantData;
  FlutterCart flutterCart = FlutterCart();
  int totalCartQuantity = 0;
  List<Widget> menuItems = [];

  @override
  void initState() {
    super.initState();
    _initializeMenuItems();
  }

  void _initializeMenuItems() {
    List<Map<String, dynamic>> menuItemsData = MenuData.menu;
    List<int> randomIndices = _generateRandomIndices(menuItemsData.length, 10);

    menuItems = randomIndices.map((index) {
      var menuItem = menuItemsData[index];
      return _buildMenuItem(
        menuItem['name'],
        menuItem['rating'],
        menuItem['price'],
        menuItem['index'],
        menuItem['itemImage'],
      );
    }).toList();

    print('Menu Items Count: ${menuItems.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_sharp),
          onPressed: () {
            flutterCart.deleteAllCart();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Menu',
          style: GoogleFonts.quicksand(
            textStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 23,
            ),
          ),
        ),
        actions: [
          Center(
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(right: 4, top: 1),
                  child: GestureDetector(
                    child: Stack(
                      children: <Widget>[
                        IconButton(
                          icon: totalCartQuantity != 0
                              ? Icon(
                                  Icons.shopping_cart_sharp,
                                  size: 38,
                                  color: Colors.black,
                                )
                              : Icon(Icons.shopping_cart_sharp,
                                  size: 38, color: Colors.grey),
                          onPressed: totalCartQuantity != 0
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          CartPage(
                                        flutterCart: flutterCart,
                                        onCartUpdated: (count) {
                                          setState(() {
                                            totalCartQuantity = count;
                                          });
                                        },
                                        restaurantName: restaurantData['name'],
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                        if (totalCartQuantity != 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: 18,
                                maxWidth: 30,
                                minHeight: 18,
                                maxHeight: 25,
                              ),
                              child: Badge(
                                badgeColor: Colors.red,
                                badgeContent: Text(
                                  totalCartQuantity.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantInfo(),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    // Extract restaurant information from the passed data
    String restaurantName = restaurantData['name'] ?? 'No Name';
    String restaurantRating = restaurantData['rating'] ?? 'N/A';
    String restaurantLocation = restaurantData['location'] ?? 'No Location';
    String restaurantImage =
        restaurantData['image'] ?? 'https://via.placeholder.com/400';

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(restaurantImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // Handle tap to show full text (you can use a dialog or tooltip)
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Text(
                            restaurantName,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 270,
                  child:Text(
                    restaurantName,
                    style: GoogleFonts.raleway(
                      textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Handle tap to show full text (you can use a dialog or tooltip)
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Text(
                            restaurantLocation,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: _buildLocationInfo(
                    Icons.location_on,
                    Colors.red,
                    restaurantLocation,
                  ),
                ),
                SizedBox(height: 4),
                _buildLocationInfo(
                  Icons.star,
                  Colors.yellow,
                  'Rating: $restaurantRating',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(IconData icon, Color color, String text) {
    return Container(
      width: 200, // Adjust the width as needed
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'For You',
              style: GoogleFonts.quicksand(
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 1,
              itemBuilder: (context, index) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    return menuItems[index];
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<int> _generateRandomIndices(int maxIndex, int count) {
    final random = Random();
    Set<int> indicesSet = {};
    while (indicesSet.length < count) {
      indicesSet.add(random.nextInt(maxIndex));
    }
    return indicesSet.toList();
  }

  Widget _buildMenuItem(
      String name, String rating, double price, int index, String itemImage) {
    print('Asset Path: $itemImage');

    return Container(
      height: 200.0,
      child: Card(
        elevation: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  image: DecorationImage(
                    image: AssetImage(itemImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 8.0, right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildText(name, 15, FontWeight.w600, Colors.black),
                  SizedBox(height: 8),
                  _buildText('\$$price', 17, null, Colors.orange),
                ],
              ),
            ),
            SizedBox(
              height: 25,
              child: Stack(children: [
                Positioned(
                  top: -15,
                  right: -3,
                  child: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      _addToCart(name, price, index, itemImage);
                    },
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(
      String text, double fontSize, FontWeight fontWeight, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }

  void _addToCart(
      String itemName, double itemPrice, int index, String itemImage) {
    bool itemExists = flutterCart.cartItem.any((item) {
      Map<String, dynamic> productDetails = item.productDetails;
      return item.productId == index.toString() &&
          productDetails != null &&
          productDetails['itemName'] == itemName;
    });

    if (itemExists) {
      flutterCart.cartItem.forEach((item) {
        Map<String, dynamic> productDetails = item.productDetails;
        if (item.productId == index.toString() &&
            productDetails != null &&
            productDetails['itemName'] == itemName) {
          item.quantity += 1;
        }
      });
    } else {
      flutterCart.addToCart(
        productId: index.toString(),
        productDetailsObject: {
          'itemName': itemName,
          'itemImage': itemImage, // Include item image URL in product details
        },
        unitPrice: itemPrice,
        quantity: 1,
      );
    }

    int totalQuantity = flutterCart.cartItem
        .map((item) => item.quantity)
        .reduce((value, element) => value + element);

    setState(() {
      totalCartQuantity = totalQuantity;
    });
  }
}
