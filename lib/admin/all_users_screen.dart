import 'dart:convert';
import 'package:blood_hub/admin/admin_user_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllUsersScreen extends StatelessWidget {
  const AllUsersScreen({super.key});

  Color _getColorForBloodGroup(String group) {
    switch (group.toUpperCase()) {
      case 'A+': return Colors.orange.shade700;
      case 'A-': return Colors.deepOrange.shade600;
      case 'B+': return Colors.blue.shade700;
      case 'B-': return Colors.indigo.shade600;
      case 'AB+': return Colors.purple.shade600;
      case 'AB-': return Colors.deepPurple.shade700;
      case 'O+': return const Color(0xFFE53935);
      case 'O-': return Colors.red.shade900;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('All Registered Users', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('emailVerified', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found in database.', style: TextStyle(fontWeight: FontWeight.bold)));
          }

          final users = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 30),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              childAspectRatio: 2.2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildUserCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String uid, Map<String, dynamic> data) {
    final String name = data['fullName'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String userType = data['userType'] ?? 'N/A';
    final String bloodGroup = data['bloodGroup'] ?? '??';
    final bool isVerified = data['isVerified'] ?? false;
    
    final Color groupColor = _getColorForBloodGroup(bloodGroup);

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => AdminUserDetailScreen(userId: uid, userData: data)));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: groupColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  bloodGroup,
                  style: TextStyle(color: groupColor, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                      if (isVerified) const SizedBox(width: 5),
                      if (isVerified) const Icon(Icons.verified, color: Colors.green, size: 16),
                    ],
                  ),
                  Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(userType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      userType.toUpperCase(),
                      style: TextStyle(color: _getTypeColor(userType), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black12),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.contains('Donor')) return Colors.red;
    if (type.contains('Hospital')) return Colors.green;
    if (type.contains('Bank')) return Colors.blue;
    return Colors.orange;
  }
}
