import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/loyalty_program_service.dart';

class LoyaltyProgramPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close_sharp)),
        title: Text('Exclusive Discounts', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF000000), // Deep Black
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                LoyaltyCouponCard(
                  title: '10% Off on Your Next Order',
                  discount: 10.0,
                  description: 'Valid until 31st Dec 2023',
                  color: const Color(0xFFFF9100),
                  backgroundImage: "assets/voucher_bg1.jpg",
                ),
                LoyaltyCouponCard(
                  title: 'Gift Voucher 20%',
                  discount: 20.0,
                  description: 'Valid for the next 2 weeks',
                  color: const Color(0xFFFF9100),
                  backgroundImage: "assets/voucher_bg2.jpg",
                ),
                LoyaltyCouponCard(
                  title: 'Gift Voucher 30%',
                  discount: 30.0,
                  description: 'Valid for the next 1 weeks',
                  color: const Color(0xFFFF9100),
                  backgroundImage: "assets/voucher_bg3.jpg",
                ),
                // Add more LoyaltyCouponCard widgets for additional coupons
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoyaltyCouponCard extends StatelessWidget {
  final String title;
  final double discount;
  final String description;
  final Color color;
  final String backgroundImage;
  final LoyaltyService loyaltyService = LoyaltyService();

  LoyaltyCouponCard({
    this.title,
    this.discount,
    this.description,
    this.color,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 7.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF0000),
              color, // Adjust opacity as needed
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipPath(
          clipper: FancyCardClipper(),
          child: Stack(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color:
                      Colors.black.withOpacity(0.5), // Adjust opacity as needed
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      description,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // Check if the user has already claimed this voucher
                        bool hasClaimed =
                            await loyaltyService.hasUserClaimedVoucher(title);

                        if (!hasClaimed) {
                          // User has not claimed the voucher, proceed with claiming
                          await loyaltyService.claimVoucher(title, discount);

                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              duration: const Duration(milliseconds: 500),
                              content:
                                  Text('$title has been succesfully claimed'),
                            ),
                          );

                          // You might want to show a confirmation dialog or navigate to a new page
                        } else {
                          // User has already claimed the voucher, disable the button
                          // Setting onPressed to null will disable the button
                          // You can also use a boolean flag to control the button's enabled state
                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              duration: const Duration(milliseconds: 500),
                              content: Text(
                                  'You have already claimed this voucher.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.redAccent[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 5,
                        ),
                        child: Text(
                          'Claim Now',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FancyCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 30);

    path.quadraticBezierTo(
        size.width / 3, size.height, size.width / 1.5, size.height - 30);

    path.quadraticBezierTo(size.width - (size.width / 8), size.height - 50,
        size.width, size.height - 80);

    path.lineTo(size.width, 0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
