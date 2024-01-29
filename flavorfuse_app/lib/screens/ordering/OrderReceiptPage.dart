import 'package:flavorfuse_app/services/order_history_service.dart';
import 'package:flavorfuse_app/shared_nav_bar/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderReceipt extends StatefulWidget {
  final Order order;
  const OrderReceipt({this.order});
  @override
  _OrderReceiptState createState() => _OrderReceiptState();
}

class _OrderReceiptState extends State<OrderReceipt> {
  bool isCartVisible = true;
  FlutterCart flutterCart;
  String finalPrice;
  double totalCost = 0.0;
  List<Map<String, dynamic>> originalOrders;
  List<Map<String, dynamic>> updatedOrders;
  final OrderHistoryService orderHistoryService = OrderHistoryService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateTotalCost();
    });
    // Deep copy the original orders
    originalOrders = widget.order.orders.map((order) {
      return Map<String, dynamic>.from(order);
    }).toList();

    // print('orginal orders: $originalOrders');
    // Store the original orders when the widget is initialized

    updatedOrders = List.from(widget.order.orders);
  }

  void resetOrders() {
    setState(() {
      // Reset orders to their original state
      widget.order.orders = List.from(originalOrders);

      // Call the method to recalculate the total cost
      updateTotalCost();
    });
  }

  void updateTotalCost() {
    if (mounted) {
      setState(() {
        totalCost = widget.order.orders.fold(
          0.0,
          (total, order) => total + (order['unit_price'] * order['quantity']),
        );
      });
    }

    updatedOrders = List.from(widget.order.orders);
  }

  void updateFinalPrice() {
    finalPrice = '${((totalCost ?? 0.0)).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_sharp, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
            resetOrders();
          },
        ),
        title: Text(
          widget.order.restaurantName,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildCartItemList(),
            _buildReorderButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.order.orders.length,
        itemBuilder: (BuildContext context, int index) {
          var item = widget.order.orders[index];

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
                    image: AssetImage(item['product_details']['itemImage']),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product_details']['itemName'],
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cost: \$${item['unit_price']} | Qty: ${item['quantity']}',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (item != null && item['quantity'] > 1) {
                        setState(() {
                          item['quantity'] -= 1;
                          updateTotalCost();
                        });
                      } else if (item != null && item['quantity'] == 1) {
                        setState(() {
                          String uuidToRemove = item['uuid'];
                          print('UUID to remove: $uuidToRemove');

                          int itemIndex = widget.order.orders.indexWhere(
                            (order) => order['uuid'] == uuidToRemove,
                          );

                          if (itemIndex != -1) {
                            print('Item index found: $itemIndex');

                            // Print the order before removal
                            print('Before removal: ${widget.order.orders}');

                            widget.order.orders.removeAt(itemIndex);

                            // Print the order after removal
                            print('After removal: ${widget.order.orders}');

                            updateTotalCost();
                          } else {
                            print('Item index not found.');
                          }
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (item != null) {
                        setState(() {
                          item['quantity'] += 1;
                          updateTotalCost();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReorderButton() {
    return ExpansionPanelList(
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
                'Order Details',
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
                  'Order No.',
                  widget.order.orderId.toString(),
                ),
                SizedBox(height: 16),
                _buildCheckoutText(
                  'Order Date',
                  widget.order.formattedDate.toString(),
                ),
                SizedBox(height: 16),
                _buildCheckoutText(
                  'Historical Cost',
                  '\$${widget.order.totalAmount.toStringAsFixed(2)}',
                ),
                Divider(
                  height: 30,
                  thickness: 1,
                  color: Colors.black45,
                ),
                _buildCheckoutText(
                  'Absolute Cost',
                  '\$${totalCost?.toStringAsFixed(2) ?? '0.00'}',
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    print('updated orders $updatedOrders');
                    DateTime orderDate = DateTime.now();
                    String userUid = orderHistoryService.getCurrentUserUid();
                    await orderHistoryService.updateOrder(
                        userUid,
                        widget.order.orderId,
                        updatedOrders,
                        double.parse(totalCost.toStringAsFixed(3)),
                        orderDate,
                        widget.order.restaurantName);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavBar(screenInt: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                    onPrimary: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Reorder',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      )),
                )
              ],
            ),
          ),
          isExpanded: isCartVisible,
        ),
      ],
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
}
