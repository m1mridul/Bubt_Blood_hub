import 'package:blood_hub/admin/all_users_screen.dart';
import 'package:blood_hub/admin/admin_blood_requests_screen.dart';
import 'package:blood_hub/admin/user_verification_detail_screen.dart';
import 'package:blood_hub/admin/suggestions_list_screen.dart';
import 'package:blood_hub/admin/update_blood_units_screen.dart';
import 'package:blood_hub/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // 1. FIXED NAVBAR
          _buildAdminNavbar(context),
          
          // 2. SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20, vertical: 40),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back, Administrator!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  const Text('Manage users, blood requests, and platform settings.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 40),
                  
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                  
                  _buildSuggestionComplaintBox(context),
                  const SizedBox(height: 25),
                  
                  _buildUpdateInventoryBox(context),
                  const SizedBox(height: 60),
                  
                  const Text('Check NID provided or not', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  _buildPendingVerificationsList(),
                  
                  const SizedBox(height: 100), // Safety bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNavbar(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/image/logo.png', 
            height: 40, 
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_,__,___)=>const Icon(Icons.bloodtype, color: Colors.red, size: 35)
          ),
          const SizedBox(width: 12),
          Text.rich(const TextSpan(children: [
            TextSpan(text: 'Blood ', style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
            TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFFE53935), fontSize: 28, fontWeight: FontWeight.w900)),
          ])),
          const Spacer(),
          _navText('Dashboard', true, () {}),
          _navText('Accounts', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AllUsersScreen()))),
          _navText('Requests', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminBloodRequestsScreen()))),
          _navText('Inventory', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UpdateBloodUnitsScreen()))),
          _navText('Feedbacks', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SuggestionsListScreen()))),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _navText(String t, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 25),
      child: InkWell(onTap: onTap, child: Text(t, style: TextStyle(color: active ? const Color(0xFFE53935) : const Color(0xFF6A6A6A), fontSize: 15, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('emailVerified', isEqualTo: true).snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('blood_requests').snapshots(),
          builder: (context, requestSnapshot) {
            final totalUsers = userSnapshot.data?.docs.length ?? 0;
            // Count users who are NOT verified but HAVE provided an NID number
            final pendingNID = userSnapshot.data?.docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['isVerified'] == false && (data['nidNumber'] != null && data['nidNumber'].toString().isNotEmpty);
            }).length ?? 0;
            final totalRequests = requestSnapshot.data?.docs.length ?? 0;
            final totalHospitals = userSnapshot.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['userType'] == 'Hospital').length ?? 0;

            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _statCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue),
                _statCard('Total Requests', totalRequests.toString(), Icons.opacity, Colors.red),
                _statCard('Hospitals', totalHospitals.toString(), Icons.local_hospital, Colors.green),
                _statCard('NID provided or not', pendingNID.toString(), Icons.badge, Colors.orange),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final users = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Show only users who are NOT verified but HAVE provided an NID
          return data['isVerified'] == false && (data['nidNumber'] != null && data['nidNumber'].toString().isNotEmpty);
        }).toList();

        if (users.isEmpty) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('No pending verifications found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: const CircleAvatar(backgroundColor: Color(0xFFFCEBEB), child: Icon(Icons.person, color: Colors.red)),
                title: Text(userData['fullName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('NID: ${userData['nidNumber'] ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserVerificationDetailScreen(userId: users[index].id, userData: userData))),
                      child: const Text('VIEW DETAILS'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(users[index].id).update({'isVerified': true});
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('APPROVE'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestionComplaintBox(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SuggestionsListScreen())),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFC62828)]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.forum_outlined, color: Colors.white, size: 35),
            const SizedBox(width: 30),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Suggestion & Complaint Box', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Read latest community feedbacks.', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateInventoryBox(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UpdateBloodUnitsScreen())),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF374151)]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 35),
            const SizedBox(width: 30),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Update Units of Blood', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Manage real-time blood stock levels.', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
