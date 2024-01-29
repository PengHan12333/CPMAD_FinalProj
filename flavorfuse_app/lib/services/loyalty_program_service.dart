import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> hasUserClaimedVoucher(String voucherCode) async {
    try {
      // Get the current user
      User user = FirebaseAuth.instance.currentUser;

      // Check if the user is signed in
      if (user != null) {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (userSnapshot.exists) {
          List<dynamic> claimedVouchers =
              userSnapshot.data()['claimedVouchers'] ?? [];

          // Check if the voucherCode exists in claimedVouchers
          return claimedVouchers.any((voucher) =>
              voucher['voucherCode'] != null &&
              voucher['voucherCode'] == voucherCode);
        }
      }
    } catch (e) {
      print('Error checking claimed voucher: $e');
    }

    // Return false by default (error or not signed in)
    return false;
  }

  Future<void> claimVoucher(String voucherCode, double discount) async {
    try {
      // Check if the user has already claimed this voucher
      bool hasClaimed = await hasUserClaimedVoucher(voucherCode);

      if (!hasClaimed) {
        // Get the current user
        User user = FirebaseAuth.instance.currentUser;

        // Check if the user is signed in
        if (user != null) {
          // Update claimed vouchers in Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'claimedVouchers': FieldValue.arrayUnion([
              {
                'voucherCode': voucherCode,
                'discount': discount,
                'dateClaimed': DateTime.now().toString(),
              }
            ]),
          });
        }
      } else {
        print('User has already claimed this voucher.');
        // You may want to handle this case in your UI (e.g., show a message)
      }
    } catch (e) {
      print('Error claiming voucher: $e');
      // Handle errors appropriately
    }
  }

  Future<List<Map<String, dynamic>>> getClaimedVouchers() async {
    try {
      // Get the current user
      User user = FirebaseAuth.instance.currentUser;

      // Check if the user is signed in
      if (user != null) {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (userSnapshot.exists) {
          List<dynamic> claimedVouchers =
              userSnapshot.data()['claimedVouchers'] ?? [];

          // Convert the claimed vouchers to a list of maps
          List<Map<String, dynamic>> claimedVouchersList =
              claimedVouchers.cast<Map<String, dynamic>>();

          return claimedVouchersList;
        }
      }
    } catch (e) {
      print('Error getting claimed vouchers: $e');
    }

    // Return an empty list by default (error or not signed in)
    return [];
  }

  Future<void> deleteClaimedVoucher(int vouchIndex) async {
    try {
      // Get the current user
      User user = FirebaseAuth.instance.currentUser;

      // Check if the user is signed in
      if (user != null && vouchIndex != null) {
        // Fetch the current claimed vouchers array
        DocumentSnapshot userSnapshotBeforeUpdate =
            await _firestore.collection('users').doc(user.uid).get();
        List<dynamic> claimedVouchers =
            userSnapshotBeforeUpdate.data()['claimedVouchers'] ?? [];

        // Ensure vouchIndex is within bounds
        if (vouchIndex >= 0 && vouchIndex < claimedVouchers.length) {
          // Remove the voucher at the specified index
          claimedVouchers.removeAt(vouchIndex);

          // Update claimed vouchers in Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'claimedVouchers': claimedVouchers,
          });

          print('Voucher deleted successfully.');
        } else {
          print('Invalid index: $vouchIndex');
        }
      }
    } catch (e) {
      print('Error deleting claimed voucher: $e');
      // Handle errors appropriately
    }
  }
}
