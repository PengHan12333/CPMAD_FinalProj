import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/loyalty_program_service.dart';
import '../../services/order_history_service.dart';
import '../../shared_nav_bar/navbar.dart';

class CartPage extends StatefulWidget {
  final FlutterCart flutterCart;
  final Function(int) onCartUpdated;
  final String restaurantName;

  CartPage({this.flutterCart, this.onCartUpdated, this.restaurantName});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  TextEditingController couponController = TextEditingController();
  double totalCost = 0.0;
  double discountOffset = 0.0; // Initialize discountOffset

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> claimedVouchers = [];
  bool isCartVisible = true;
  String finalPrice;
  int selectedCouponIndex;

  int voucherUsed;
  String get restaurantName => widget.restaurantName;
  final OrderHistoryService orderHistoryService = OrderHistoryService();
  final LoyaltyService loyaltyService = LoyaltyService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateTotalCost();
      updateTotalCartQuantity();
      fetchClaimedVouchers(); // Fetch claimed vouchers when the page loads
    });
  }

  void updateFinalPrice() {
    finalPrice =
        '${((totalCost ?? 0.0) - (discountOffset ?? 0.0)).toStringAsFixed(2)}';
  }

  Future<void> fetchClaimedVouchers() async {
    try {
      LoyaltyService loyaltyService = LoyaltyService();
      List<Map<String, dynamic>> vouchers =
          await loyaltyService.getClaimedVouchers();

      setState(() {
        claimedVouchers = vouchers;
      });
    } catch (e) {
      print('Error fetching claimed vouchers: $e');
    }
  }

  void updateTotalCost() {
    if (mounted) {
      totalCost = widget.flutterCart.cartItem.fold(
        0,
        (total, cartItem) => total + (cartItem.unitPrice * cartItem.quantity),
      );

      setState(() {
        widget.onCartUpdated(totalCost?.toInt() ?? 0);
      });
    }
  }

  void updateTotalCartQuantity() {
    if (widget.flutterCart.cartItem.isNotEmpty) {
      int totalQuantity = widget.flutterCart.cartItem
          .map((item) => item.quantity)
          .reduce((value, element) => value + element);

      widget.onCartUpdated(totalQuantity);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.quicksand(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.close_sharp),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 4, // Set the elevation to add a shadow
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.flutterCart.getCartItemCount(),
              itemBuilder: (context, index) {
                var cartItem = widget.flutterCart.cartItem[index];
                String itemName = cartItem.productDetails['itemName'];
                String itemImage = cartItem.productDetails['itemImage'];

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(itemImage),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Cost: \$${cartItem.unitPrice} | Qty: ${cartItem.quantity}',
                                style: GoogleFonts.roboto(
                                  textStyle: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle_sharp),
                      color: Colors.red,
                      onPressed: () {
                        _decrementQuantity(cartItem.productId);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ExpansionPanelList(
            elevation: 1,
            expandedHeaderPadding: EdgeInsets.zero,
            expansionCallback: (int panelIndex, bool isExpanded) {
              setState(() {
                isCartVisible = !isCartVisible;
              });
            },
            children: [
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    title: Text(
                      'Order Summary',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  );
                },
                body: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCheckoutText(
                        'Total Cost',
                        '\$${totalCost?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      SizedBox(height: 16),
                      _buildCheckoutText(
                        'Discount Offset',
                        '\$${(totalCost > 0 ? discountOffset : discountOffset = 0.0).toStringAsFixed(2) ?? '0.00'}',
                      ),
                      Divider(
                        height: 30,
                        thickness: 1,
                        color: Colors.black45,
                      ),
                      _buildCheckoutText(
                        'Final Price',
                        "\$$finalPrice",
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _showCouponBottomSheet();
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black,
                          onPrimary: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Apply Coupon',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          // Check if the cart is empty
                          if (widget.flutterCart.cartItem.isEmpty) {
                            // Display an error message or any appropriate UI indication
                            print(
                                'Cannot proceed with checkout. Cart is empty.');

                            // Show a toast message
                            Fluttertoast.showToast(
                              msg:
                                  'Cannot proceed with checkout. Cart is empty.',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red[700],
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );

                            return;
                          }
                          DateTime orderDate = DateTime.now();
                          String userUid =
                              orderHistoryService.getCurrentUserUid();
                          // Add the order to the order history
                          await orderHistoryService.addOrderHistory(
                              widget.flutterCart,
                              userUid,
                              orderDate,
                              restaurantName,
                              double.parse(finalPrice));

                          await loyaltyService
                              .deleteClaimedVoucher(voucherUsed);

                          await widget.flutterCart.deleteAllCart();

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BottomNavBar(screenInt: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                          onPrimary: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Checkout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ],
                  ),
                ),
                isExpanded: isCartVisible,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutText(String title, String value) {
    updateFinalPrice();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _decrementQuantity(String productId) {
    var cartItem = widget.flutterCart.cartItem.firstWhere(
      (item) => item.productId == productId,
      orElse: () => null,
    );

    if (cartItem != null && cartItem.quantity > 1) {
      setState(() {
        cartItem.quantity -= 1;
        updateTotalCost();
        updateTotalCartQuantity();
        if (selectedCouponIndex != null) {
          _applyCoupon(claimedVouchers[selectedCouponIndex]);
        }
      });
    } else if (cartItem != null && cartItem.quantity == 1) {
      setState(() {
        int itemIndex = widget.flutterCart.cartItem.indexOf(cartItem);
        if (itemIndex != -1) {
          widget.flutterCart.deleteItemFromCart(itemIndex);
        }
        updateTotalCost();
        updateTotalCartQuantity();
        if (selectedCouponIndex != null) {
          _applyCoupon(claimedVouchers[selectedCouponIndex]);
        }
      });
    }
  }

  void _showCouponBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(13.0),
                child: Text(
                  'Choose a Coupon',
                  style: GoogleFonts.quicksand(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: claimedVouchers.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    Map<String, dynamic> voucher = claimedVouchers[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Icon(
                          Icons.local_offer,
                          color: Colors.orange,
                          size: 30,
                        ),
                        title: Text(
                          '${voucher['voucherCode']}',
                          style: GoogleFonts.quicksand(
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        subtitle: Text(
                          'Discount: ${voucher['discount']}%',
                          style: GoogleFonts.openSans(
                            textStyle: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close the bottom sheet
                          setState(() {
                            selectedCouponIndex = index;
                          });
                          _applyCoupon(claimedVouchers[index]);
                          voucherUsed = index;
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyCoupon(Map<String, dynamic> voucher) {
    if (widget.flutterCart.cartItem.isEmpty ||
        totalCost == null ||
        voucher['discount'] == null) {
      return; // Ensure there are items in the cart and no null values
    }

    setState(() {
      if (totalCost > 0) {
        discountOffset = (voucher['discount'] / 100) * totalCost;
      } else {
        discountOffset = 0.0;
      }
    });
  }
}
