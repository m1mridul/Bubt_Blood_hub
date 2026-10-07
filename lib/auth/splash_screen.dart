import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_hub/auth/login_screen.dart'; 
import 'package:blood_hub/user/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/blood_hand.png',
              width: 250, 
              height: 250,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.volunteer_activism, size: 150, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'Blood ', style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
                  TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFFE53935), fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Every Drop Saves a Life',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
