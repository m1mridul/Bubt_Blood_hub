import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalContactScreen extends StatelessWidget {
  const HospitalContactScreen({super.key});

  final List<Map<String, String>> hospitals = const [
    {
      'name': 'Dhaka Medical College Hospital',
      'address': 'Ramna, Dhaka-1000',
      'phone': '02-9669340',
    },
    {
      'name': 'Square Hospital',
      'address': '18/F, West Panthapath, Dhaka-1205',
      'phone': '10616',
    },
    {
      'name': 'United Hospital',
      'address': 'Plot 15, Road 71, Gulshan, Dhaka-1212',
      'phone': '10666',
    },
    {
      'name': 'Evercare Hospital Dhaka',
      'address': 'Plot 81, Block E, Bashundhara R/A, Dhaka-1229',
      'phone': '10678',
    },
    {
      'name': 'Labaid Specialized Hospital',
      'address': 'House 06, Road 04, Dhanmondi, Dhaka-1205',
      'phone': '10606',
    },
    {
      'name': 'Birdem General Hospital',
      'address': '122, Kazi Nazrul Islam Ave, Shahbagh, Dhaka-1000',
      'phone': '02-9661551',
    },
    {
      'name': 'Ibn Sina Specialized Hospital',
      'address': 'House 48, Road 9/A, Dhanmondi, Dhaka-1209',
      'phone': '10615',
    },
    {
      'name': 'Popular Specialized Hospital',
      'address': 'House 16, Road 2, Dhanmondi, Dhaka-1205',
      'phone': '09613787801',
    },
    {
      'name': 'Holy Family Red Crescent Hospital',
      'address': '1, Eskaton Garden Road, Dhaka-1000',
      'phone': '02-8311721',
    },
    {
      'name': 'Kurmitola General Hospital',
      'address': 'Airport Road, Dhaka Cantonment, Dhaka',
      'phone': '02-55062347',
    },
  ];

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Hospital ', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
              TextSpan(text: 'Directory', style: TextStyle(color: Color(0xFFE53935), fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.15 : 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contacts',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 10),
            const Text(
              'A list of major hospitals in Dhaka city for quick contact and coordination.',
              style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 40),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                final hospital = hospitals[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.local_hospital, color: Color(0xFFE53935), size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital['name']!,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    hospital['address']!,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hospital['phone']!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE53935)),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _makeCall(hospital['phone']!),
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('CALL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
