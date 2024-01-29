import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:flutter_cart/model/cart_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class Order {
  final int orderNumber;
  final String restaurantName;
  final DateTime orderDate;
  final String formattedDate; // Add formattedDate property
  final double totalAmount;
  final int orderId;
  List<dynamic> orders;

  Order(this.orderNumber, this.restaurantName, this.orderDate, this.totalAmount,
      this.orders, this.orderId,
      [this.formattedDate = ""]);
}

class OrderHistoryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addOrderHistory(
    FlutterCart flutterCart,
    String uid,
    DateTime orderDate,
    String restaurantName,
    double fullPrice,
  ) async {
    CollectionReference orderHistoryCollection =
        _firestore.collection('orderhistory');

    DocumentReference userDocRef = orderHistoryCollection.doc(uid);

    // Fetch current order history
    DocumentSnapshot userDoc = await userDocRef.get();

    if (userDoc.exists) {
      // Determine the new order ID
      List<dynamic> orders = userDoc.data()['orders'] ?? [];
      int newOrderId = orders.isNotEmpty ? orders.last['orderId'] + 1 : 1;

      List<Map<String, dynamic>> cartItemsMap = [];

      flutterCart.cartItem.forEach((item) {
        if (item is CartItem) {
          cartItemsMap.add({
            "uuid": item.uuid,
            "product_id": item.productId,
            "unit_price": item.unitPrice,
            "sub_total": item.subTotal,
            "unique_check": item.uniqueCheck,
            "quantity": item.quantity,
            "product_details": item.productDetails,
          });
        }
      });

      // Append the new order to the orders array
      orders.add({
        'orderId': newOrderId,
        'orderDate': orderDate,
        'restaurantName': restaurantName,
        'fullPrice': fullPrice,
        'cartItems': cartItemsMap,
      });

      // Update the document with the modified orders array
      await userDocRef.update({'orders': orders});

      // Show toast for successful order placement
      Fluttertoast.showToast(
        msg: 'Order placed successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      // If the document doesn't exist, create a new document with UID and order
      await userDocRef.set({
        'orders': [
          {
            'orderId': 1,
            'orderDate': orderDate,
            'restaurantName': restaurantName,
            'fullPrice': fullPrice,
            'cartItems': [],
          },
        ],
      });

      // Show toast for successful order placement
      Fluttertoast.showToast(
        msg: 'Order placed successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<List<Order>> getOrderHistory(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('orderhistory').doc(uid).get();

      if (userDoc.exists) {
        List<Order> orderList = [];
        List<dynamic> orders = userDoc.data()['orders'] ?? [];

        for (var orderData in orders) {
          Timestamp orderTimestamp = orderData['orderDate'];
          DateTime orderDate = orderTimestamp.toDate();

          // Format the date using 'dd MMMM yyyy' pattern
          String formattedDate = DateFormat('dd MMMM yyyy').format(orderDate);

          orderList.add(
            Order(
              orderData['orderId'],
              orderData['restaurantName'],
              orderDate,
              orderData['fullPrice'].toDouble(),
              orderData['cartItems'],
              orderData['orderId'],
              formattedDate,
            ),
          );
        }

        return orderList;
      } else {
        return [];
      }
    } catch (e) {
      // Handle or log the error
      print('Error fetching order history: $e');
      return [];
    }
  }

  Future<double> calculateTotalAmountSpent(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('orderhistory').doc(uid).get();

      if (userDoc.exists) {
        double totalAmount = 0;
        List<dynamic> orders = userDoc.data()['orders'] ?? [];

        for (var orderData in orders) {
          totalAmount += orderData['fullPrice'].toDouble();
        }

        return totalAmount;
      } else {
        return 0.0; // or any default value
      }
    } catch (e) {
      // Handle or log the error
      print('Error calculating total amount spent: $e');
      return 0.0; // or any default value
    }
  }

  Future<void> updateOrder(
      String uid,
      int orderId,
      List<Map<String, dynamic>> updatedCartItems,
      double newFullPrice,
      DateTime newOrderDate,
      String restaurantName) async {
    try {
      CollectionReference orderHistoryCollection =
          FirebaseFirestore.instance.collection('orderhistory');
      DocumentReference userDocRef = orderHistoryCollection.doc(uid);

      // Fetch current order history
      DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        List<dynamic> orders = userDoc.data()['orders'] ?? [];

        // Find the index of the order with the given orderId
        int orderIndex =
            orders.indexWhere((order) => order['orderId'] == orderId);

        if (orderIndex != -1) {
          if (newFullPrice == 0) {
            // Remove the order with orderId from orders array
            orders.removeAt(orderIndex);

            // Reassign orderId starting from 1 for remaining orders
            for (int i = 0; i < orders.length; i++) {
              orders[i]['orderId'] = i + 1;
            }

            Fluttertoast.showToast(
              msg: 'Order No. $orderId for $restaurantName has been cancelled!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            // Update the entire order with the new data
            orders[orderIndex]['cartItems'] = updatedCartItems;
            orders[orderIndex]['fullPrice'] = newFullPrice;
            orders[orderIndex]['orderDate'] = newOrderDate;

            Fluttertoast.showToast(
              msg: 'Order No. $orderId for $restaurantName has been updated!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }

          // Update the document with the modified orders array
          await userDocRef.update({'orders': orders});
        } else {
          // Handle case where order with given orderId is not found
          print('Order with orderId $orderId not found.');
        }
      } else {
        // Handle case where user document is not found
        print('User document not found.');
      }
    } catch (e) {
      // Handle or log the error
      print('Error updating order: $e');
    }
  }

  // Get the UID of the currently signed-in user
  String getCurrentUserUid() {
    return _auth.currentUser?.uid ?? '';
  }
}
