import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlavorFuse',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.quicksandTextTheme().copyWith(
          headline6: TextStyle(color: Colors.white), // AppBar text color
          bodyText2: TextStyle(color: Colors.white), // Body text color
        ),
      ),
      home: AboutUsPage(),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.grey[900]],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
                width: 120,
              ),
              SizedBox(height: 20),
              Text(
                'Welcome to FlavorFuse',
                style: GoogleFonts.quicksand(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Our Mission',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Revolutionizing the dining experience in Singapore\'s Smart Nation. We seamlessly connect users with the diverse culinary landscape, creating a unified and delightful journey for every palate.',
                style: GoogleFonts.quicksand(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Contact Us',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3),
              ContactCard(
                developerName: 'Heng Peng Han',
                phoneNumber: '9656 5646',
                emailAddress: 'customer_support@flavorfuse.org',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final String developerName;
  final String phoneNumber;
  final String emailAddress;

  const ContactCard({
    Key key,
    this.developerName,
    this.phoneNumber,
    this.emailAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 20),
      color: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer Information',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Colors.orangeAccent,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Name: $developerName',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () => _launchPhoneCall(phoneNumber),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.orangeAccent,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    phoneNumber,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () => _launchEmail(emailAddress),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: Colors.orangeAccent,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    emailAddress,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to launch a phone call
  void _launchPhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to launch an email
  void _launchEmail(String emailAddress) async {
    final url = 'mailto:$emailAddress';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
