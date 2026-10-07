import 'dart:convert';
import 'package:blood_hub/user/emergency_requests_list_screen.dart';
import 'package:blood_hub/user/find_donors_screen.dart';
import 'package:blood_hub/auth/login_screen.dart';
import 'package:blood_hub/auth/registration_screen.dart';
import 'package:blood_hub/user/request_details_screen.dart';
import 'package:blood_hub/user/my_personal_requests_screen.dart';
import 'package:blood_hub/user/my_request_responses_screen.dart';
import 'package:blood_hub/user/my_account_screen.dart';
import 'package:blood_hub/user/my_history_screen.dart';
import 'package:blood_hub/user/hospital_contact_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:blood_hub/user/post_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _emergencyCount = 0;
  Map<String, dynamic>? _userData;
  bool _isUserDataLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isNavbarSticky = false;

  @override
  void initState() {
    super.initState();
    _listenToEmergencyRequests();
    _fetchUserData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isNavbarSticky) {
      setState(() => _isNavbarSticky = true);
    } else if (_scrollController.offset <= 50 && _isNavbarSticky) {
      setState(() => _isNavbarSticky = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (user == null) {
      setState(() => _isUserDataLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _isUserDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isUserDataLoading = false);
    }
  }

  void _listenToEmergencyRequests() {
    FirebaseFirestore.instance
        .collection('blood_requests')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _emergencyCount = snapshot.docs.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ELIGIBILITY CHECK FOR BANNER
    final Timestamp? nextEligibleDate = _userData?['nextEligibilityDate'];
    final bool isResting = nextEligibleDate != null && nextEligibleDate.toDate().isAfter(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                if (isResting) _buildEligibilityBanner(nextEligibleDate!),
                const SizedBox(height: 120),
                Center(
                  child: SizedBox(
                    width: 1440,
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 100),
                        _buildStatsBanner(),
                        const SizedBox(height: 100),
                        _buildPersonalRequestsBox(),
                        const SizedBox(height: 30),
                        _buildRequestResponsesBox(),
                        const SizedBox(height: 120),
                        _buildRoleSection(),
                        const SizedBox(height: 120),
                        _buildAvailabilitySection(),
                        const SizedBox(height: 120),
                        _buildBottomRequestBanner(),
                        const SizedBox(height: 150),
                        _buildHowItWorksSection(),
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
          _buildStickyNavbar(),
        ],
      ),
    );
  }

  Widget _buildEligibilityBanner(Timestamp date) {
    final diff = date.toDate().difference(DateTime.now()).inDays;
    return Container(
      width: double.infinity,
      color: const Color(0xFFE53935),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'YOU ARE NOT ELIGIBLE TO ACCEPT ANY REQUEST. REST PERIOD ACTIVE FOR NEXT $diff DAYS.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 600,
      padding: const EdgeInsets.symmetric(horizontal: 100),
      child: Stack(
        children: [
          Positioned(
            left: 450, top: 0, bottom: 0,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/image/world_map.png', width: 900, fit: BoxFit.contain, errorBuilder: (_,__,___)=>const SizedBox()),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Donate Blood.\n', style: TextStyle(color: Colors.black, fontSize: 64, fontWeight: FontWeight.w900)),
                  const TextSpan(text: 'Saves', style: TextStyle(color: Color(0xFFE53935), fontSize: 64, fontWeight: FontWeight.w900)),
                  const TextSpan(text: ' Lives.', style: TextStyle(color: Color(0xFFE53935), fontSize: 64, fontWeight: FontWeight.w900)),
                ])),
                const SizedBox(height: 25),
                const Text(
                  'Blood Hub connects donors, receivers and hospitals\nto make blood donation easy, fast and reliable.',
                  style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 45),
                Row(
                  children: [
                    _btn('Become a Donor', const Color(0xFFE53935), Colors.white, icon: Icons.favorite, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const RegistrationScreen()))),
                    const SizedBox(width: 25),
                    _btn('Request Blood', Colors.transparent, const Color(0xFF212121), imageIcon: 'assets/image/logo.png', hasBorder: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const PostRequestScreen()))),
                  ],
                ),
                const SizedBox(height: 50),
                _buildDonorRealtimeCount(),
              ],
            ),
          ),
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: Image.asset('assets/image/blood_hand.png', width: 550, fit: BoxFit.contain, errorBuilder: (_,__,___)=>const SizedBox()),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorRealtimeCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('emailVerified', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final totalVerifiedUsers = snapshot.data?.docs.length ?? 0;
        return Row(
          children: [
            _overlapAvatars(),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalVerifiedUsers > 1000 ? '${(totalVerifiedUsers / 1000).toStringAsFixed(1)}k+' : '$totalVerifiedUsers+', 
                  style: const TextStyle(color: Color(0xFFE53935), fontSize: 26, fontWeight: FontWeight.bold)
                ),
                const Text('Happy Users', style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildRoleSection() {
    return Column(
      children: [
        const Text('Choose Your Role', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHoverRoleCard("I'm a Donor", "Donates bloods and help\nsave someone's life.", "Become a Donor", const Color(0xFFE53935), const Color(0xFFFCEBEB), () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const RegistrationScreen()))),
            const SizedBox(width: 25),
            _buildHoverRoleCard("I Need Blood", "Search donors and\nrequest blood easily.", "Request Blood", const Color(0xFF2E7D32), const Color(0xFFEAF2EB), () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const PostRequestScreen()))),
            const SizedBox(width: 25),
            _buildHoverRoleCard("I'm a Hospital", "Manage blood inventory\nand donor request.", "Hospital Portal", const Color(0xFF3535E5), const Color(0xFFEBECFC), () {}),
            const SizedBox(width: 25),
            _buildHoverRoleCard("Platform Admin", "Manage users and\nverify documents.", "Admin Portal", const Color(0xFFE535B6), const Color(0xFFFCEBF8), () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      children: [
        const Text('Blood Availability', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _availabilityCard('O-', '38 Units', 'Critical', const Color(0xFFE53935), 0.3),
                const SizedBox(width: 25),
                _availabilityCard('O+', '240 Units', 'Low', const Color(0xFF858707), 0.5),
                const SizedBox(width: 25),
                _availabilityCard('A+', '340 Units', 'Stable', const Color(0xFF2E7D32), 0.8),
                const SizedBox(width: 25),
                _availabilityCard('A-', '96 Units', 'Low', const Color(0xFF858707), 0.4),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _availabilityCard('B+', '188 Units', 'Stable', const Color(0xFF2E7D32), 0.7),
                const SizedBox(width: 25),
                _availabilityCard('B-', '22 Units', 'Critical', const Color(0xFFE53935), 0.2),
                const SizedBox(width: 25),
                _availabilityCard('AB+', '168 Units', 'Stable', const Color(0xFF2E7D32), 0.6),
                const SizedBox(width: 25),
                _availabilityCard('AB-', '41 Units', 'Low', const Color(0xFF858707), 0.4),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStickyNavbar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 100),
      decoration: BoxDecoration(
        color: _isNavbarSticky ? Colors.white.withOpacity(0.98) : const Color(0xFFFAFAFA),
        boxShadow: _isNavbarSticky ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))] : [],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/image/logo.png', 
            height: 45, 
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_,__,___) => const Icon(Icons.bloodtype, color: Colors.red, size: 40)
          ),
          const SizedBox(width: 12),
          Text.rich(const TextSpan(children: [
            TextSpan(text: 'Blood ', style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w900)),
            TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFFE53935), fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w900)),
          ])),
          const Spacer(),
          const SizedBox(width: 40),
          _navText('Home', true, () {}),
          _navText('Find Donor', false, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const FindDonorsScreen()))),
          _navText('Blood Request', false, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const PostRequestScreen()))),
          _buildEmergencyNavText(),
          _navText('My History', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MyHistoryScreen()))),
          _navText('Contact', false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HospitalContactScreen()))),
          const SizedBox(width: 40),
          if (user == null) ...[
            _navBtn('Login', Colors.transparent, Colors.black, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const LoginScreen()))),
            const SizedBox(width: 15),
            _navBtn('Sign Up', const Color(0xFFE53935), Colors.white, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const RegistrationScreen()))),
          ] else 
            _buildAccountNavIcon(),
        ],
      ),
    );
  }

  Widget _buildAccountNavIcon() {
    final bool isVerified = _userData?['isVerified'] ?? false;
    final String? profilePic = _userData?['profilePicture'];

    return InkWell(
      onTap: () {
        if (_userData != null) {
          Navigator.push(context, MaterialPageRoute(builder: (c) => MyAccountScreen(userData: _userData!)));
        }
      },
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFCEBEB),
                backgroundImage: profilePic != null ? MemoryImage(base64Decode(profilePic)) : null,
                child: profilePic == null ? const Icon(Icons.person, color: Color(0xFFE53935), size: 20) : null,
              ),
              if (isVerified)
                const Icon(Icons.verified, color: Colors.green, size: 14),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      width: 1240, padding: const EdgeInsets.symmetric(vertical: 35),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [const BoxShadow(color: Color(0x140F172A), blurRadius: 40, offset: Offset(0, 12))]),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('emailVerified', isEqualTo: true).snapshots(),
        builder: (context, userSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('blood_requests').snapshots(),
            builder: (context, requestSnapshot) {
              final totalVerifiedUsers = userSnapshot.data?.docs.length ?? 0;
              final totalRequests = requestSnapshot.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'active').length ?? 0;
              // Only count requests that reached 'certified' status as lives saved
              final livesSaved = requestSnapshot.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'certified').length ?? 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(totalVerifiedUsers, 'Registered Users', Icons.people_rounded, Colors.blue),
                  _statItem(totalRequests, 'Active Requests', Icons.opacity, Colors.red),
                  _statItem(2, 'Hospitals', Icons.local_hospital_rounded, Colors.green),
                  _statItem(livesSaved, 'Lives saved', Icons.favorite_rounded, Colors.red.shade900),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statItem(int target, String label, IconData icon, Color color) {
    return Row(children: [
      Container(
        width: 70, height: 70, 
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
        child: Icon(icon, color: color, size: 30)
      ),
      const SizedBox(width: 20),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: target),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) => Text('${value.toString()}+', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        Text(label, style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    ]);
  }

  Widget _buildPersonalRequestsBox() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MyPersonalRequestsScreen())),
      child: Container(
        width: 1240, padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF374151)]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 12))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 35)),
          const SizedBox(width: 30),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('My Personal Requests', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Track requests you sent to specific donors and check their responses.', style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold))]),
          const Spacer(),
          const Text('VIEW ALL', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE53935), size: 20),
        ]),
      ),
    );
  }

  Widget _buildRequestResponsesBox() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MyRequestResponsesScreen())),
      child: Container(
        width: 1240, padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 12))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 35)),
          const SizedBox(width: 30),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('My Request Responses', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('See which donors have accepted your blood requests and coordinate with them.', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold))]),
          const Spacer(),
          const Text('VIEW RESPONSES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
          const SizedBox(width: 12),
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
        ]),
      ),
    );
  }

  Widget _buildBottomRequestBanner() {
    return Container(
      width: 1240, height: 200,
      decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFE53935).withOpacity(0.15)), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))]),
      child: Stack(children: [
        Positioned(left: 350, top: 0, bottom: 0, right: 350, child: Opacity(opacity: 0.12, child: Image.asset('assets/image/heart_pulse.png', fit: BoxFit.fitHeight, errorBuilder: (_,__,___)=>const SizedBox()))),
        Row(children: [
          const SizedBox(width: 60),
          Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20)]), child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFE53935), size: 45)),
          const SizedBox(width: 40),
          const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Need Blood Urgently?', style: TextStyle(color: Color(0xFFE53935), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)), SizedBox(height: 12), Text('Create an emergency request and get help from nearby donors.', style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 18, fontWeight: FontWeight.bold))]),
          const Spacer(),
          _HoverContainer(builder: (isHovered) => AnimatedScale(scale: isHovered ? 1.05 : 1.0, duration: const Duration(milliseconds: 200), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const PostRequestScreen())), child: Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Request Now', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)), SizedBox(width: 15), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24)]))))),
          const SizedBox(width: 40),
          Image.asset('assets/image/blood_hand.png', width: 180, fit: BoxFit.contain, errorBuilder: (_,__,___)=>const SizedBox()),
          const SizedBox(width: 40),
        ]),
      ]),
    );
  }

  Widget _buildHowItWorksSection() {
    return Column(children: [
      const Text('How It Works', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black)),
      const SizedBox(height: 80),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_howStep('1.Register', 'Create your account as donor or receiver.', Icons.person_add_alt_1_outlined), _howLine(), _howStep('2.Search/Request', 'Find donors or send blood request.', Icons.search), _howLine(), _howStep('3.Connect', 'Connect & confirm details securely.', Icons.phone_in_talk_outlined), _howLine(), _howStep('4.Donate', 'Donate or help by providing blood.', Icons.opacity), _howLine(), _howStep('5.Save Life', 'Your donation can save a precious life.', Icons.favorite_border)]),
    ]);
  }

  Widget _howStep(String title, String desc, IconData icon) => SizedBox(width: 220, child: Column(children: [Container(width: 90, height: 90, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]), child: Icon(icon, color: const Color(0xFFE53935), size: 35)), const SizedBox(height: 25), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.bold))]));

  Widget _howLine() => Container(width: 60, height: 2, margin: const EdgeInsets.only(bottom: 110), child: Row(children: List.generate(10, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.black12 : Colors.transparent, height: 2)))));

  Widget _overlapAvatars() => SizedBox(width: 180, height: 60, child: Stack(children: List.generate(5, (index) => Positioned(left: index * 30.0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)]), child: CircleAvatar(radius: 28, backgroundColor: const Color(0xFFFEEAEA), backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=${index + 10}')))))));

  Widget _navText(String t, bool active, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(right: 30), child: InkWell(onTap: onTap, child: Text(t, style: TextStyle(color: active ? const Color(0xFFE53935) : const Color(0xFF6A6A6A), fontSize: 17, fontFamily: 'Manrope', fontWeight: FontWeight.bold))));

  Widget _buildEmergencyNavText() => Padding(padding: const EdgeInsets.only(right: 30), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EmergencyRequestListScreen())), child: Stack(clipBehavior: Clip.none, children: [const Text('Emergency Request', style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 17, fontFamily: 'Manrope', fontWeight: FontWeight.bold)), if (_emergencyCount > 0) Positioned(right: -20, top: -10, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 20, minHeight: 20), child: Center(child: Text('$_emergencyCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))))])));

  Widget _navBtn(String t, Color bg, Color text, VoidCallback onTap) => InkWell(onTap: onTap, child: Container(width: 120, height: 56, decoration: BoxDecoration(color: bg, border: bg == Colors.transparent ? Border.all(color: const Color(0xFF6A6A6A), width: 1.5) : null, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(t, style: TextStyle(color: text, fontSize: 17, fontFamily: 'Manrope', fontWeight: FontWeight.w900)))));

  Widget _buildFooter() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 100), color: const Color(0xFF111827),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Blood Hub', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 25),
            const Text('Empowering communities through reliable and fast blood donation connections.', style: TextStyle(color: Colors.white60, fontSize: 18, height: 1.6, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Row(children: [_socialIcon(Icons.facebook), const SizedBox(width: 20), _socialIcon(Icons.camera_alt_outlined), const SizedBox(width: 20), _socialIcon(Icons.language)])
          ])),
          const Spacer(),
          _footerColumn('Platform', ['Find Donors', 'Hospital Portal', 'Requests', 'Statistics']),
          _footerColumn('Support', ['Contact Us', 'About Hub', 'FAQs', 'Policies']),
        ]),
        const SizedBox(height: 80),
        const Divider(color: Colors.white10),
        const SizedBox(height: 40),
        const Text('© 2026 BUBT Blood Hub. Developed with ❤️ for saving lives.', style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _footerColumn(String t, List<String> links) {
    return Padding(padding: const EdgeInsets.only(left: 80), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 30),
      ...links.map((l) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(l, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)))),
    ]));
  }

  Widget _socialIcon(IconData i) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: Icon(i, color: Colors.white, size: 22));

  Widget _buildHoverRoleCard(String title, String desc, String btn, Color color, Color bg, VoidCallback onTap) {
    return _HoverContainer(builder: (isHovered) => AnimatedScale(scale: isHovered ? 1.05 : 1.0, duration: const Duration(milliseconds: 200), child: _roleCard(title, desc, btn, color, bg, onTap)));
  }

  Widget _roleCard(String title, String desc, String btn, Color color, Color bg, VoidCallback onTap) {
    return Container(width: 280, height: 300, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [const BoxShadow(color: Color(0x140F172A), blurRadius: 40, offset: Offset(0, 12))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(Icons.person, color: color, size: 35)),
      const SizedBox(height: 20),
      Text(title, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 14, fontWeight: FontWeight.bold))),
      const SizedBox(height: 25),
      InkWell(onTap: onTap, child: Container(width: 220, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(btn, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))))),
    ]));
  }

  Widget _availabilityCard(String group, String units, String status, Color color, double progress) {
    return _HoverContainer(builder: (isHovered) => AnimatedScale(scale: isHovered ? 1.05 : 1.0, duration: const Duration(milliseconds: 200), child: Container(width: 290, height: 200, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: isHovered ? color.withOpacity(0.1) : const Color(0x140F172A), blurRadius: 40, offset: const Offset(0, 12))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(group, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
      const Spacer(),
      LinearProgressIndicator(value: progress, color: color, backgroundColor: const Color(0xFFE9E9E9), minHeight: 8),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(units, style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 16, fontWeight: FontWeight.bold)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))),
      ]),
    ]))));
  }

  Widget _btn(String t, Color bg, Color text, {IconData? icon, String? imageIcon, VoidCallback? onTap, bool hasBorder = false}) {
    return _HoverContainer(builder: (isHovered) => AnimatedScale(scale: isHovered ? 1.05 : 1.0, duration: const Duration(milliseconds: 200), child: InkWell(onTap: onTap, child: Container(width: 212, height: 58, decoration: BoxDecoration(color: bg, border: hasBorder ? Border.all(color: const Color(0xFFE5E7EB), width: 2) : null, borderRadius: BorderRadius.circular(12), boxShadow: isHovered ? [BoxShadow(color: (bg == Colors.transparent ? Colors.black : bg).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))] : []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (icon != null) Icon(icon, color: hasBorder ? const Color(0xFFE53935) : Colors.white, size: 22),
      if (imageIcon != null) Image.asset(imageIcon, height: 30, fit: BoxFit.contain, errorBuilder: (_,__,___)=>const Icon(Icons.opacity, color: Colors.red)),
      const SizedBox(width: 12),
      Text(t, style: TextStyle(color: text, fontSize: 18, fontFamily: 'Manrope', fontWeight: FontWeight.bold)),
    ])))));
  }
}

class _HoverContainer extends StatefulWidget {
  final Widget Function(bool isHovered) builder;
  const _HoverContainer({required this.builder});
  @override
  _HoverContainerState createState() => _HoverContainerState();
}

class _HoverContainerState extends State<_HoverContainer> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false), cursor: SystemMouseCursors.click, child: widget.builder(_isHovered));
  }
}
