import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OTPService {
  static var _correctOTP; // Store the correct OTP

  // Internal Method to set the correct OTP
  static Future<String> setCorrectOTP(String correctOTP) async {
    
    return _correctOTP = correctOTP;
  }

  // Method to verify the entered OTP
  static Future<bool> verifyOTP(String enteredOTP) async {
    await Future.delayed(Duration.zero); // Ensure this method is asynchronous
    print('Current _correctOTP: "$_correctOTP"');
    if (_correctOTP == null) {
      // Handle the case where correct OTP is not set (perhaps due to an error)
      showCustomToast(
          'Error: Correct OTP not set. Please try again.', Colors.red[700]);
      return false;
    }

    print('Entered OTP: "$enteredOTP"');
    print('Correct OTP: "$_correctOTP"');

    // Compare the entered OTP with the correct OTP, ignoring case and whitespaces
    bool isVerified = enteredOTP.trim() == _correctOTP.trim();

    print('Comparison result: $isVerified');

    if (isVerified) {
      print('Verification successful!');
    } else {
      print('Verification failed!');
    }

    // Show a toast message indicating whether the OTP is verified or not
    showCustomToast(
      isVerified
          ? 'OTP verification successful'
          : 'Incorrect OTP. Please try again.',
      isVerified ? Colors.green[700] : Colors.red[700],
    );

    return isVerified;
  }

  static Future<String> sendVerificationEmail(String email) async {
    try {
      // Generate a 4-digit OTP
      String otp = await generateFourDigitOTP();

      // Send the OTP to the user's email
      await sendOTP(email, otp);

      // Show a success message to the user
      showCustomToast(
          'OTP verification email sent successfully', Colors.green[700]);

      // Return the generated OTP
      return otp;
    } catch (e) {
      // Handle error and show a toast message
      showCustomToast('Error sending OTP verification email', Colors.red[700]);
      return null; // Return null in case of an error
    }
  }

  static Future<void> sendOTP(String email, String otp) async {
    final smtpServer = SmtpServer(
      'smtp.gmail.com', // Replace with your SMTP server host
      username:
          'flavorfuseappbobby@gmail.com', // Replace with your SMTP username
      password: 'jxoq tnbi qytf vqex', // Replace with your SMTP password
      port: 587
    );

    final message = Message()
      ..from = Address('flavorfuseappbobby@gmail.com', 'FlavorFuse App')
      ..recipients.add(email)
      ..subject = 'FlavorFuse App - OTP Verification'
      ..html = '''
        <p>Dear User,</p>
        <p>Your OTP for FlavorFuse App is: <strong>$otp</strong></p>
        <p>Thank you for using our app.</p>
        <p>Best regards,<br>FlavorFuse App Team</p>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } catch (e) {
      print('Error sending email: $e');
      // Handle the error as needed (e.g., show a toast message)
      throw e;
    }
  }

  // Internal method to generate a 4-digit OTP and set it
  static Future<String> generateFourDigitOTP() async {
    print('Generating OTP...');

    // Generate the OTP
    String otp =
        ((DateTime.now().millisecondsSinceEpoch % 9000) + 1000).toString();

    // Set the correct OTP
    await setCorrectOTP(otp);

    return otp;
  }

  // Custom toast message
  static void showCustomToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
      // Try adjusting the time delay
      timeInSecForIosWeb: 2,
    );
  }
}
