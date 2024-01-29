import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flavorfuse_app/models/user.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<MyUser> authStateChanges() {
    return _auth.authStateChanges().asyncMap<MyUser>((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      } else {
        try {
          // Fetch user data from Firestore
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();

          // Check if the document exists
          if (!userDoc.exists) {
            print('User document does not exist.');
            return null;
          }

          // Log the entire document data for debugging
          print('User Document Data: ${userDoc.data()}');

          // Check and convert the fields
          String fullName = userDoc['fullname']?.toString() ?? '';
          String password = userDoc['password']?.toString() ?? '';
          String photoURL = userDoc['profileImageUrl']?.toString() ?? '';

          // Create a MyUser object with the fetched data
          MyUser user = MyUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            fullName: fullName,
            password: password,
            photoURL: photoURL,
          );

          print('User Information: $user');

          return user;
        } catch (e, stackTrace) {
          print('Error fetching user data: $e\n$stackTrace');
          return null;
        }
      }
    });
  }

  Future<MyUser> getCurrentUserInfo() async {
    try {
      User user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String fullname = userDoc['fullname'] ?? '';
        String email = userDoc['email'] ?? '';
        String password = userDoc['password'] ?? '';
        String imageUrl = userDoc['profileImageUrl'] ?? '';

        MyUser currentUser = MyUser(
          fullName: fullname,
          email: email,
          password: password,
          photoURL: imageUrl,
        );

        return currentUser;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw Exception('Error fetching user data');
    }
  }

  Future<User> signUp({String email, String password}) async {
    try {
      UserCredential ucred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = ucred.user;
      print('Signed Up successful! user: $user');
      return user;
    } on FirebaseAuthException catch (e) {
      showCustomToast(e.message);
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> addUserInformation(
      String uid, String fullName, String email, String pass) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'fullname': fullName,
        'password': pass,
        'profileImageUrl': '', // You can set a default value or leave it empty
      });
    } catch (e) {
      print('Error adding user information: $e');
      // Handle error as needed, e.g., show an error message to the user
      throw e;
    }
  }

// Login an existing user with email and password
  Future<void> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle login error and show toast message
      showCustomToast('Login failed. Please check your credentials.');
      // Handle the error or rethrow it for the UI to handle (if needed)
      throw e;
    } catch (e) {
      // Handle other errors (if any)
      print('Error logging in: $e');
      throw e;
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if a user is currently signed in
  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }

  // Get the UID of the currently signed-in user
  String getCurrentUserUid() {
    return _auth.currentUser?.uid ?? '';
  }

  void showCustomToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP, // Set gravity to bottom
      backgroundColor: Colors.red[700], // Adjust the shade for a brighter red
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
