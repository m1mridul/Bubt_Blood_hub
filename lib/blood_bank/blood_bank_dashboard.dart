import 'package:blood_hub/blood_bank/blood_bank_post_request_screen.dart';
import 'package:blood_hub/auth/login_screen.dart';
import 'package:blood_hub/admin/update_blood_units_screen.dart';
import 'package:blood_hub/user/emergency_requests_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BloodBankDashboard extends StatefulWidget {
  final String bankEmail;
  const BloodBankDashboard({super.key, required this.bankEmail});

  @override
  State<BloodBankDashboard> createState() => _BloodBankDashboardState();
}

class _BloodBankDashboardState extends State<BloodBankDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isNavbarSticky = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _isNavbarSticky = _scrollController.offset > 20;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F2),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Blood Bank Operations', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF7C2D12))),
                      const Text('Monitor inventory, manage local donors, and verify collections.', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 40),
                      
                      _buildRealtimeStatsRow(),
                      const SizedBox(height: 40),

                      _buildActionGrid(context),
                      const SizedBox(height: 40),

                      const Text('Live Inventory Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12))),
                      const SizedBox(height: 20),
                      _buildInventorySummary(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBankNavbar(context),
        ],
      ),
    );
  }

  Widget _buildRealtimeStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('blood_inventory').snapshots(),
      builder: (context, snapshot) {
        int totalUnits = 0;
        int criticalCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            int units = (doc.data() as Map<String, dynamic>)['units'] ?? 0;
            totalUnits += units;
            if (units < 20) criticalCount++;
          }
        }

        return Row(
          children: [
            _statCard('Total Stock', '$totalUnits Units', Icons.inventory_2, Colors.brown),
            const SizedBox(width: 25),
            _statCard('Verified Donors', '1,240', Icons.verified_user, Colors.green),
            const SizedBox(width: 25),
            _statCard('Critical Groups', criticalCount.toString().padLeft(2, '0'), Icons.warning_amber_rounded, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildInventorySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('blood_inventory').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final docs = snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final group = docs[index].id;
            final units = data['units'] ?? 0;
            final status = data['status'] ?? 'Stable';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Text(group, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$units Units', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(status, style: TextStyle(color: units < 20 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  )
                ],
              ),
            );
          },
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

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 30,
      mainAxisSpacing: 30,
      childAspectRatio: 2.5,
      children: [
        _actionBox('Manage Inventory', 'Update real-time blood stock levels.', Icons.add_to_photos_rounded, const Color(0xFF7C2D12), () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const UpdateBloodUnitsScreen()))),
        _actionBox('Collection Registry', 'Verify and record external donations.', Icons.app_registration_rounded, Colors.green.shade800, () {}),
        _actionBox('Request Spectator', 'View urgent needs in your locality.', Icons.visibility_outlined, Colors.blue.shade800, () {}),
        _actionBox('Donor Outreach', 'Send alerts to eligible donors.', Icons.campaign_rounded, Colors.orange.shade800, () {}),
      ],
    );
  }

  Widget _actionBox(String t, String s, IconData i, Color c, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: c.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: c.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, color: c, size: 28)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(s, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: c.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildBankNavbar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 90, width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 100),
      decoration: BoxDecoration(
        color: _isNavbarSticky ? Colors.white.withOpacity(0.98) : Colors.white,
        boxShadow: _isNavbarSticky ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
      ),
      child: Row(
        children: [
          const Icon(Icons.opacity, color: Color(0xFF7C2D12), size: 30),
          const SizedBox(width: 10),
          const Text('Bank Portal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF7C2D12))),
          const Spacer(),
          _navText('Dashboard', true, () {}),
          _navText('Blood Request', false, () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => BloodBankPostRequestScreen(bankEmail: widget.bankEmail)));
          }),
          _navText('Inventory', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UpdateBloodUnitsScreen()))),
          _navText('Live Requests', false, () {}),
          const SizedBox(width: 30),
          ElevatedButton.icon(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('EXIT'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C2D12), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _navText(String t, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: InkWell(onTap: onTap, child: Text(t, style: TextStyle(color: active ? const Color(0xFF7C2D12) : Colors.brown.shade300, fontSize: 16, fontWeight: FontWeight.bold))),
    );
  }
}
