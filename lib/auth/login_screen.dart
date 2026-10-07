import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:blood_hub/auth/registration_screen.dart';
import 'package:blood_hub/user/home_screen.dart';
import 'package:blood_hub/admin/admin_login_screen.dart';
import 'package:blood_hub/hospital/hospital_login_screen.dart';
import 'package:blood_hub/blood_bank/blood_bank_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      User? user = userCredential.user;
      
      if (user != null) {
        // Force reload to get the latest emailVerified status
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          // ENSURE Firestore is updated even if it was false during registration
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'emailVerified': true,
          }, SetOptions(merge: true));

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // Email not verified, sign out and show message
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Email Not Verified'),
                content: const Text('Please check your inbox and click the verification link before logging in.'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // Option to resend verification
                      try {
                        // We need to sign in again briefly to resend verification or just use the credential
                        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        await cred.user?.sendEmailVerification();
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Verification email resent!"), backgroundColor: Colors.blue),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('RESEND LINK'),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                ],
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Error"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogoHeader(),
                      const SizedBox(height: 50),
                      _buildHeroSection(),
                      const SizedBox(height: 50),
                      _buildFeatureBar(),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: Container(
              color: const Color(0xFFF9FAFB),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: _buildLoginCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/image/logo.png', 
          height: 40, 
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          errorBuilder: (_, __, ___) => const Icon(Icons.bloodtype, color: Colors.red, size: 35)
        ),
        const SizedBox(width: 10),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Blood ', style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
              TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFFE53935), fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Every Drop', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D), letterSpacing: -1)),
        Row(
          children: [
            const Text('Saves a Life ', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFFD9534F), letterSpacing: -1)),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFD9534F), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Text(
          'Join our community and help bridge the gap\nbetween donors and those in urgent need.',
          style: TextStyle(fontSize: 18, color: Colors.black45, height: 1.4, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
            ),
            Image.asset(
              'assets/image/blood_hand.png',
              height: 400, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.volunteer_activism, size: 250, color: Color(0xFFD9534F)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _featureItem(Icons.verified_outlined, 'Verified Donors'),
        _featureItem(Icons.lock_outline, 'Secure System'),
        _featureItem(Icons.headset_mic_outlined, '24/7 Support'),
      ],
    );
  }

  Widget _featureItem(IconData icon, String t) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFFEEAEA), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFFD9534F), size: 20),
        ),
        const SizedBox(width: 12),
        Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('Welcome', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
          const SizedBox(height: 12),
          const Center(child: Text('Login to continue your life-saving journey', style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.bold))),
          const SizedBox(height: 35),
          
          _buildInstitutionalAccessGrid(),
          const SizedBox(height: 35),

          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151))),
          const SizedBox(height: 12),
          _buildField(
            _emailController, 
            'Enter your email', 
            Icons.mail_outline,
            errorText: _emailError,
            onChanged: (val) {
              setState(() {
                int atCount = val.split('@').length - 1;
                if (val.isNotEmpty && (atCount != 1 || !val.endsWith('@gmail.com'))) {
                  _emailError = "Please type valid email";
                } else {
                  _emailError = null;
                }
              });
            },
          ),
          const SizedBox(height: 25),
          const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151))),
          const SizedBox(height: 12),
          _buildField(_passwordController, 'Enter your password', Icons.lock_outline, isPass: true),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                SizedBox(height: 18, width: 18, child: Checkbox(value: _rememberMe, onChanged: (v)=>setState(()=>_rememberMe=v!), activeColor: const Color(0xFFD9534F), side: const BorderSide(color: Colors.black26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
                const SizedBox(width: 8),
                const Text('Remember me', style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold)),
              ]),
              TextButton(onPressed: (){}, child: const Text('Forgot password?', style: TextStyle(color: Color(0xFFD9534F), fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD9534F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(width: 10), Icon(Icons.arrow_forward, size: 20)]),
            ),
          ),
          const SizedBox(height: 40),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text("Don't have account? ", style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.bold)),
            GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const RegistrationScreen())), child: const Text('Sign UP', style: TextStyle(color: Color(0xFFD9534F), fontWeight: FontWeight.bold, fontSize: 14))),
          ])),
        ],
      ),
    );
  }

  Widget _buildInstitutionalAccessGrid() {
    return Column(
      children: [
        _accessBox(
          title: 'Administrator',
          subtitle: 'Official Admin Portal',
          icon: Icons.admin_panel_settings_outlined,
          color: const Color(0xFF1F2937),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminLoginScreen())),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _accessBox(
                title: 'Hospital',
                subtitle: 'Portal',
                icon: Icons.local_hospital_outlined,
                color: const Color(0xFF1E3A8A),
                compact: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HospitalLoginScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _accessBox(
                title: 'Blood Bank',
                subtitle: 'Community',
                icon: Icons.opacity,
                color: const Color(0xFF7C2D12),
                compact: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BloodBankLoginScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accessBox({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, bool compact = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: compact ? 20 : 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: compact ? 13 : 15, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: compact ? 9 : 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String h, IconData i, {bool isPass = false, String? errorText, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: errorText != null ? Colors.red : const Color(0xFFE5E7EB))
          ),
          child: TextField(
            controller: c, obscureText: isPass && _obscurePassword,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: h, hintStyle: const TextStyle(fontSize: 14, color: Colors.black26, fontWeight: FontWeight.bold),
              prefixIcon: Icon(i, color: Colors.black26, size: 20),
              suffixIcon: isPass ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black26, size: 20), onPressed: ()=>setState(()=>_obscurePassword=!_obscurePassword)) : null,
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 5),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
