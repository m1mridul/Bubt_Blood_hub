import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DonorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> donorData;

  const DonorProfileScreen({super.key, required this.donorData});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    final String name = donorData['fullName'] ?? 'N/A';
    final String bloodGroup = donorData['bloodGroup'] ?? 'N/A';
    final String? profilePic = donorData['profilePicture'];
    final String location = "${donorData['area'] ?? ''}, ${donorData['district'] ?? ''}, ${donorData['division'] ?? ''}";
    
    // Using dummy data if fields don't exist in Firestore yet
    final int totalDonations = donorData['totalDonations'] ?? 0;
    final String nextEligibility = donorData['nextEligibility'] ?? 'Available Now';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Donor Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeaderCard(profilePic, name, bloodGroup, location),
                const SizedBox(height: 24),
                _buildStatsSection(totalDonations, nextEligibility),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(),
                const SizedBox(height: 40),
                _buildActionButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String? profilePic, String name, String bloodGroup, String location) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFFFCEBEB),
            backgroundImage: profilePic != null ? MemoryImage(base64Decode(profilePic)) : null,
            child: profilePic == null ? const Icon(Icons.person, size: 60, color: Color(0xFFE53935)) : null,
          ),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(15)),
            child: Text(
              'Blood Group: $bloodGroup',
              style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int total, String eligibility) {
    return Row(
      children: [
        Expanded(child: _statCard('Total Donations', total.toString(), Icons.favorite, Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Eligibility', eligibility, Icons.event_available, Colors.green)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _infoRow(Icons.mail_outline, 'Email Address', donorData['email'] ?? 'N/A'),
          const SizedBox(height: 20),
          _infoRow(Icons.phone_outlined, 'Phone Number', donorData['phone'] ?? 'N/A'),
          const SizedBox(height: 20),
          _infoRow(Icons.verified_user_outlined, 'Account Status', donorData['isVerified'] == true ? 'Verified' : 'Pending Verification'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFE53935), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ],
        )
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          // Implement request logic
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to donor!')));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: const Text('SEND DONATION REQUEST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
