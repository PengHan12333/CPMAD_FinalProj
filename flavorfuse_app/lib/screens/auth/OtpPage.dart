import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../models/user.dart';
import '../../services/authentication_service.dart';
import '../../services/otp_service.dart';
import '../../shared_nav_bar/navbar.dart';

class OtpPage extends StatefulWidget {
  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  TextEditingController _otpController;
  bool _isResending = false;
  int _resendTimer = 30;
  Timer _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_disposed) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _isResending = false;
            _resendTimer = 30;
            _timer.cancel();
          }
        });
      } else {
        _timer.cancel();
      }
    });
  }

  void _resendOtp() async {
    if (!_disposed) {
      setState(() {
        _isResending = true;
        _resendTimer = 30;
      });
      // Implement logic to resend OTP via email
      // You should use a backend or a service to send the OTP to the user's email
      // Retrieve the user's email
      MyUser currentUser = await AuthenticationService().getCurrentUserInfo();
      String userEmail = currentUser.email;
      await OTPService.sendVerificationEmail(userEmail);
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer.cancel(); // Cancel the timer when the component is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C1C), Color(0xFF393939)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          // Navigate back
                          Navigator.pop(context);
                        },
                      ),
                      Column(
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 125.0,
                            width: 125.0,
                          ),
                          SizedBox(height: 20.0),
                          Text(
                            'Enter the 4-digit PIN sent to your email',
                            style: TextStyle(
                              color: Colors.blueGrey[900],
                              fontSize: 16.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40.0),
                            child: PinCodeTextField(
                              appContext: context,
                              length: 4,
                              controller: _otpController,
                              obscureText: true,
                              animationType: AnimationType.fade,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.underline,
                                borderRadius: BorderRadius.circular(5),
                                fieldHeight: 50,
                                fieldWidth: 40,
                                activeFillColor: Colors.transparent,
                                inactiveFillColor: Colors.transparent,
                                selectedFillColor: Colors.transparent,
                                activeColor: Colors.blueGrey[900],
                                inactiveColor: Colors.grey[300],
                                selectedColor: Colors.blueGrey[900],
                              ),
                              onChanged: (value) {
                                print("Changed: $value");
                              },
                              onCompleted: (pin) {
                                print("Completed: $pin");
                              },
                            ),
                          ),
                          SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: () async {
                              if (_otpController.text.isNotEmpty) {
                                print(
                                    "your controller text ${_otpController.text}");
                                // Call the verifyOTP method from OTPService
                                bool isOTPVerified = await OTPService.verifyOTP(
                                    _otpController.text);

                                if (isOTPVerified) {
                                  // Add your logic for a successful OTP verification
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BottomNavBar()),
                                  );
                                  print("OTP verification successful");
                                } else {
                                  // Add your logic for unsuccessful OTP verification
                                  print("Incorrect OTP. Please try again.");
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.blueGrey[900],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40.0, vertical: 15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Text(
                              'Verify OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          if (_isResending)
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'Resend OTP in $_resendTimer seconds',
                                style: TextStyle(
                                  color: Colors.blueGrey[900],
                                ),
                              ),
                            ),
                          if (!_isResending)
                            TextButton(
                              onPressed: () {
                                _resendOtp();
                              },
                              child: Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: Colors.blueGrey[900],
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
        ),
      ),
    );
  }
}
