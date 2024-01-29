import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user.dart';
import '../../services/authentication_service.dart';
import '../auth/LoginPage.dart';

class ProfileImagePicker extends StatefulWidget {
  final File pickedImage;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  ProfileImagePicker({
    this.pickedImage,
    this.onTap,
    this.onEdit,
  });

  @override
  _ProfileImagePickerState createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  String _profileImageUrl = '';

  Future<MyUser> getCurrentUserData() async {
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
        _profileImageUrl = userDoc['profileImageUrl'] ?? '';

        MyUser currentUser = MyUser(
          fullName: fullname,
          email: email,
          password: password,
          photoURL: _profileImageUrl,
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

  Future<void> clearImageCache(String imageUrl) async {
    await CachedNetworkImageProvider(imageUrl).evict();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyUser>(
      future: getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError || snapshot.data == null) {
          // Handle the error or null data condition
          return Text('Error: Unable to fetch user data');
        } else {
          MyUser user = snapshot.data;

          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.pickedImage != null
                        ? FileImage(widget.pickedImage)
                        : user?.photoURL != null && user.photoURL.isNotEmpty
                            ? CachedNetworkImageProvider(user.photoURL)
                            : CachedNetworkImageProvider(
                                'https://placekitten.com/100/100',
                              ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red[800],
                    ),
                    child: IconButton(
                      onPressed: widget.onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File _pickedImage;
  String newImageUrl;

  Future<void> _updateProfile() async {
    try {
      User user = _auth.currentUser;

      if (user != null) {
        // Retrieve the plain-text password from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String storedPassword = userDoc.data()['password'];
        String storedEmail = userDoc.data()['email'];
        String storedImageUrl = userDoc.data()['profileImageUrl'];

        // Reauthenticate to update email and password
        AuthCredential credential = EmailAuthProvider.credential(
          email: storedEmail,
          password: storedPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Verify the new email before updating
        await verifyBeforeUpdateEmail(user, _emailController.text);

        await user.updatePassword(_passwordController.text);

        // Check if a new image is selected
        // Delete existing image in Firebase Storage
        if (user.photoURL != null && user.photoURL.isNotEmpty) {
          try {
            await _storage.refFromURL(user.photoURL).delete();
          } catch (e) {
            if (e is FirebaseException && e.code == 'object-not-found') {
              // Handle case when the object is not found (image already deleted)
              print('Image already deleted or not found.');
            } else {
              // Handle other deletion errors
              print('Error deleting existing image: $e');
            }
          }
        }

        // Check if a new image is selected
        if (_pickedImage != null) {
          // Upload new image to Firebase Storage
          final ref = _storage.ref().child('${user.uid}');
          await ref.putFile(_pickedImage);
          newImageUrl = await ref.getDownloadURL();
        } else {
          // Use the existing profileImageUrl if no new image is selected
          newImageUrl = storedImageUrl;
        }

        // Update the user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _emailController.text,
          'fullname': _nameController.text,
          'password': _passwordController.text,
          'profileImageUrl': newImageUrl,
          // Add other fields as needed
        });

        // Notify listeners or perform other actions
      }
    } catch (e) {
      print('Error updating user profile: $e');
      // Handle errors accordingly
    }
  }

  Future<bool> doesEmailExist(String email) async {
    try {
      User user = _auth.currentUser;

      // Retrieve the plain-text password from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String storedPassword = userDoc.data()['password'];
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: storedPassword);

      // Email exists
      return true;
    } catch (e) {
      // Email does not exist
      return false;
    }
  }

  Future<void> verifyBeforeUpdateEmail(User user, String newEmail) async {
    try {
      // Send a verification email to the new email address
      await user.verifyBeforeUpdateEmail(newEmail);

      // Display a message to the user indicating that a verification email has been sent
      print(
          'Verification email sent to $newEmail. Please check your inbox to complete the update.');

      // You may want to wait for the user to verify the email before proceeding further
      // You can check the verification status using user.emailVerified
    } catch (e) {
      print('Error sending verification email: $e');
      // Handle error (e.g., show a message to the user)
    }
  }

  Future<void> _pickAndSetImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    } else {
      // Handle image picking cancellation or error
      // Optionally, you can set _pickedImage to null if you want to clear the previously picked image
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Profile',
          style: GoogleFonts.quicksand(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<MyUser>(
        stream: AuthenticationService().authStateChanges(),
        builder: (context, snapshot) {
          MyUser user = snapshot.data;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Colors.grey[900]],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileImagePicker(
                        pickedImage: _pickedImage,
                        onTap: _pickAndSetImage,
                        onEdit: _pickAndSetImage,
                      ),
                      SizedBox(height: 10),
                      _buildTextField(
                        'Name',
                        user?.fullName ?? 'John Doe',
                        _nameController,
                        Icons.person,
                        subtitle: 'Your full name',
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2),
                      _buildTextField(
                        'Email',
                        user?.email ?? 'john.doe@example.com',
                        _emailController,
                        Icons.email,
                        subtitle: 'Your email address',
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(
                                  r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2),
                      _buildTextField(
                        'Password',
                        user?.password ?? '********',
                        _passwordController,
                        Icons.lock,
                        subtitle: 'Your password',
                        obscureText: true,
                        validator: (value) {
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState.validate()) {
                            // Form is valid, proceed with update

                            // Check if the email exists in Firebase Auth
                            bool emailExists =
                                await doesEmailExist(_emailController.text);

                            if (emailExists) {
                              // Email exists, pass verificationEmailSent: false
                              await _updateProfile();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                      verificationEmailSent: "false"),
                                ),
                              );
                            } else {
                              // Email does not exist, pass verificationEmailSent: true
                              await _updateProfile();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                      verificationEmailSent: "true"),
                                ),
                              );
                            }
                          } else {
                            // Form is not valid, show an error message
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please fix the errors in the form.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String currentValue,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
    String subtitle = '',
    String Function(String) validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14), // Add bottom margin for spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          subtitle.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                )
              : SizedBox.shrink(),
          Container(
            height: 80,
            padding: EdgeInsets.only(bottom: 2), // Add bottom padding
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: label,
                hintText: currentValue,
                labelStyle: TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Increased border radius
                  borderSide: BorderSide(
                    color: Colors.grey[800],
                    width: 2, // Increased border width
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[500], width: 1.5),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(
                    icon,
                    color: Colors.grey,
                  ),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
