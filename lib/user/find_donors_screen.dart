import 'dart:convert';
import 'package:blood_hub/user/donor_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FindDonorsScreen extends StatefulWidget {
  const FindDonorsScreen({super.key});

  @override
  State<FindDonorsScreen> createState() => _FindDonorsScreenState();
}

class _FindDonorsScreenState extends State<FindDonorsScreen> {
  String? _selectedBloodGroup;
  List<QueryDocumentSnapshot> _donors = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Future<void> _findDonors() async {
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a blood group to search.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('bloodGroup', isEqualTo: _selectedBloodGroup)
          .where('userType', isEqualTo: 'Blood Donor')
          .get();

      setState(() {
        _donors = querySnapshot.docs;
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

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
      default: return const Color(0xFFE53935);
    }
  }

  Future<void> _sendPersonalRequest(Map<String, dynamic> donorData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String donorId = donorData['uid'] ?? "";
    final String donorName = donorData['fullName'] ?? "Donor";
    final String bloodGroup = donorData['bloodGroup'] ?? "N/A";

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('personal_requests').add({
        'requesterId': currentUser.uid,
        'donorId': donorId,
        'donorName': donorName,
        'bloodGroup': bloodGroup,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to $donorName successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Find ', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
              TextSpan(text: 'Donors', style: TextStyle(color: Color(0xFFE53935), fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(isDesktop),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : _donors.isEmpty
                    ? _buildEmptyState()
                    : _buildDonorGrid(isDesktop, size),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search Volunteers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBloodGroup,
                      hint: const Text('Select Blood Group', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black26)),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black26),
                      items: _bloodGroups.map((group) => DropdownMenuItem(
                        value: group,
                        child: Text(group, style: const TextStyle(fontWeight: FontWeight.bold)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedBloodGroup = val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _findDonors,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    elevation: 0,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Search', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonorGrid(bool isDesktop, Size size) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 30),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        childAspectRatio: isDesktop ? 1.5 : 2.2,
        crossAxisSpacing: 25,
        mainAxisSpacing: 25,
      ),
      itemCount: _donors.length,
      itemBuilder: (context, index) {
        final data = _donors[index].data() as Map<String, dynamic>;
        return _buildDonorCard(data);
      },
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> data) {
    final String name = data['fullName'] ?? 'N/A';
    final String location = data['area'] ?? data['location'] ?? 'Not specified';
    final String bloodGroup = data['bloodGroup'] ?? 'N/A';
    final String eligibility = data['nextEligibility'] ?? 'Available Now';
    final bool isEligible = !eligibility.contains('days');

    final Color groupColor = _getColorForBloodGroup(bloodGroup);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 65, height: 65,
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      bloodGroup,
                      style: TextStyle(color: groupColor, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(location, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEligible ? "Available Now" : eligibility,
                        style: TextStyle(color: isEligible ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorProfileScreen(donorData: data),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isEligible ? () => _sendPersonalRequest(data) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEligible ? const Color(0xFFE53935) : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                    ),
                    child: Text(isEligible ? 'Request' : 'Unavailable', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _hasSearched ? 'No donors found' : 'Find volunteers near you',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 10),
          Text(
            _hasSearched ? 'Try searching for another blood group.' : 'Select a blood group and click search.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
