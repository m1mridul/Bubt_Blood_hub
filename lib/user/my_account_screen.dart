import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_hub/auth/login_screen.dart';

class MyAccountScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MyAccountScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    final bool isVerified = userData['isVerified'] ?? false;
    final String fullName = userData['fullName'] ?? 'User';
    final String username = userData['username'] ?? 'username';
    final String email = userData['email'] ?? 'N/A';
    final String phone = userData['phone'] ?? 'N/A';
    final String bloodGroup = userData['bloodGroup'] ?? 'N/A';
    final String userType = userData['userType'] ?? 'N/A';
    final String location = "${userData['area'] ?? ''}, ${userData['district'] ?? ''}, ${userData['division'] ?? ''}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Manrope')),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.25 : 20, vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFFCEBEB),
                        backgroundImage: userData['profilePicture'] != null 
                            ? MemoryImage(base64Decode(userData['profilePicture'])) 
                            : null,
                        child: userData['profilePicture'] == null 
                            ? const Icon(Icons.person, size: 60, color: Color(0xFFE53935)) 
                            : null,
                      ),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified, color: Colors.green, size: 28),
                        ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(fullName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '@$username', 
                    style: const TextStyle(color: Color(0xFFE53935), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isVerified ? 'Verified Account' : 'Verification Pending',
                    style: TextStyle(color: isVerified ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  const Divider(height: 1),
                  const SizedBox(height: 40),
                  _infoRow(Icons.mail_outline, 'Email Address', email),
                  const SizedBox(height: 20),
                  _infoRow(Icons.phone_outlined, 'Phone Number', phone),
                  const SizedBox(height: 20),
                  _infoRow(Icons.opacity, 'Blood Group', bloodGroup),
                  const SizedBox(height: 20),
                  _infoRow(Icons.person_pin_outlined, 'User Type', userType),
                  const SizedBox(height: 20),
                  _infoRow(Icons.location_on_outlined, 'Location', location),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('LOGOUT FROM ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFFE53935), size: 22),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            ],
          ),
        )
      ],
    );
  }
}
