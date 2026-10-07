import 'package:blood_hub/hospital/hospital_active_requests_screen.dart';
import 'package:blood_hub/hospital/hospital_certify_screen.dart';
import 'package:blood_hub/auth/login_screen.dart';
import 'package:blood_hub/user/post_request_screen.dart';
import 'package:blood_hub/admin/update_blood_units_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HospitalDashboard extends StatefulWidget {
  final String hospitalEmail;
  const HospitalDashboard({super.key, required this.hospitalEmail});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  String _getHospitalName() {
    if (widget.hospitalEmail.contains('hospital1')) return 'Dhaka Medical College Hospital';
    if (widget.hospitalEmail.contains('hospital2')) return 'Square Hospital';
    if (widget.hospitalEmail.contains('hospital3')) return 'United Hospital';
    if (widget.hospitalEmail.contains('hospital4')) return 'Evercare Hospital Dhaka';
    return 'Labaid Specialized Hospital';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final String currentHospital = _getHospitalName();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portal: $currentHospital', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      const Text('Manage emergency requests and justify donor contributions.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 40),
                      
                      _buildRealtimeStatsRow(currentHospital),
                      const SizedBox(height: 40),

                      _buildOurActiveRequestsBox(currentHospital),
                      const SizedBox(height: 20),

                      _buildCertificationBox(currentHospital),
                      const SizedBox(height: 30),

                      if (isDesktop) _buildQuickActions(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildHospitalNavbar(context),
        ],
      ),
    );
  }

  Widget _buildRealtimeStatsRow(String hospitalName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('blood_requests').where('hospitalName', isEqualTo: hospitalName).snapshots(),
      builder: (context, snapshot) {
        final allRequests = snapshot.data?.docs ?? [];
        final activeCount = allRequests.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'active').length;
        final certifiedCount = allRequests.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'certified').length;
        
        return Row(
          children: [
            _statCard('Our Active Requests', activeCount.toString(), Icons.campaign, Colors.orange),
            const SizedBox(width: 25),
            _statCard('Total Certified', certifiedCount.toString(), Icons.verified, Colors.blue),
            const SizedBox(width: 25),
            _statCard('Successful Saved', (certifiedCount * 1.5).toInt().toString(), Icons.volunteer_activism, Colors.red),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String val, IconData i, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(i, color: c, size: 30),
            const SizedBox(height: 15),
            Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildOurActiveRequestsBox(String hospitalName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('blood_requests')
          .where('hospitalName', isEqualTo: hospitalName)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HospitalActiveRequestsScreen(hospitalName: hospitalName))),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 28)),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Our Active Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('View current blood requests waiting for donors at your institution.', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                  child: Text('$count ACTIVE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildCertificationBox(String hospitalName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('blood_requests')
          .where('hospitalName', isEqualTo: hospitalName)
          .where('status', isEqualTo: 'completed_by_receiver')
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.docs.length ?? 0;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HospitalCertifyScreen(hospitalName: hospitalName))),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 35)),
                const SizedBox(width: 25),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Spectator & Certified the Donor', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    Text('Verify and certify successful donations to update donor eligibility and records.', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                ),
                if (pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                const Text('ACCESS NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHospitalNavbar(BuildContext context) {
    return Container(
      height: 90, width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 100),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: Color(0xFF1E3A8A), size: 30),
          const SizedBox(width: 10),
          const Text('Hospital Portal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('LOGOUT'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionCard('High-Priority Request', Icons.add_alert, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const PostRequestScreen()))),
        const SizedBox(width: 20),
        _actionCard('Inventory', Icons.inventory_2, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const UpdateBloodUnitsScreen()))),
      ],
    );
  }

  Widget _actionCard(String t, IconData i, Color c, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Icon(i, color: Colors.white, size: 24),
              const SizedBox(width: 15),
              Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
