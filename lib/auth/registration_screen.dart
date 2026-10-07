import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nidController = TextEditingController();
  final _licenseController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedCityCorp;
  String? _selectedArea;
  String _userType = 'Blood Donor';
  String? _selectedBloodGroup;
  String? _emailError;
  String? _nidError;
  String? _phoneError;
  
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isNidUploaded = false;
  bool _isLoading = false;

  Uint8List? _nidImage;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Input Error', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _divisions = ['Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'];
  
  final Map<String, List<String>> _districtsMap = {
    'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail', 'Manikganj', 'Munshiganj'],
    'Chattogram': ['Chattogram', 'Cox\'s Bazar', 'Cumilla', 'Feni', 'Noakhali'],
  };

  final Map<String, List<String>> _dhakaCityCorps = {
    'North City Corporation': ['Uttara', 'Mirpur', 'Gulshan', 'Banani', 'Mohammadpur', 'Badda', 'Khilkhet', 'Pallabi'],
    'South City Corporation': ['Dhanmondi', 'Shahbagh', 'Motijheel', 'Jatrabari', 'Lalbagh', 'Hazaribagh', 'Wari', 'Kamrangirchar'],
  };

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_suggestUsername);
  }

  void _suggestUsername() {
    if (_fullNameController.text.isNotEmpty) {
      String name = _fullNameController.text.toLowerCase().replaceAll(' ', '');
      if (name.length > 8) name = name.substring(0, 8);
      // Adding a random 3 digit number for uniqueness suggestion
      String suggested = "$name${_fullNameController.text.length}${DateTime.now().second}";
      _usernameController.text = suggested;
    }
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_suggestUsername);
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickNidImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() { _nidImage = bytes; _isNidUploaded = true; });
    }
  }

  Future<void> _register() async {
    // Basic Information validation
    if (_fullNameController.text.trim().isEmpty || 
        _usernameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty ||
        _selectedDivision == null ||
        _selectedDistrict == null ||
        _selectedArea == null) {
      _showErrorDialog('Please fill up the full form');
      return;
    }

    // Specific Detail validation
    if (_userType == 'Blood Donor' || _userType == 'Blood Seeker') {
      if (_selectedBloodGroup == null || _nidController.text.trim().isEmpty) {
        _showErrorDialog('Please provide blood group and NID number');
        return;
      }
    } else {
      if (_licenseController.text.trim().isEmpty) {
        _showErrorDialog('Please provide License/Registration number');
        return;
      }
    }

    // Real-time error checks
    if (_emailError != null || _nidError != null || _phoneError != null) {
      _showErrorDialog('Please correct the errors in the form before proceeding');
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms & Policy')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String? nidImageUrl;
      if (_nidImage != null) nidImageUrl = base64Encode(_nidImage!);

      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        
        Map<String, dynamic> userData = {
          'fullName': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': '+880${_phoneController.text.trim()}',
          'userType': _userType,
          'division': _selectedDivision,
          'district': _selectedDistrict,
          'cityCorp': _selectedCityCorp,
          'area': _selectedArea,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
          'emailVerified': false, // Initial state
          'totalDonations': 0,
          'nextEligibility': 'Available Now',
        };

        if (_userType == 'Blood Donor' || _userType == 'Blood Seeker') {
          userData['bloodGroup'] = _selectedBloodGroup;
          userData['nidNumber'] = _nidController.text.trim();
          userData['nidImage'] = nidImageUrl;
        } else {
          userData['licenseNumber'] = _licenseController.text.trim();
          userData['additionalNotes'] = _additionalNotesController.text.trim();
        }

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text('A verification link has been sent. Please verify before logging in.'),
            actions: [
              TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK')),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error"), backgroundColor: Colors.red));
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
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogoHeader(),
                    const Spacer(),
                    _buildHeroIllustration(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: Container(
              color: const Color(0xFFF9FAFB),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildRegisterCard(),
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
        Text.rich(const TextSpan(children: [
          TextSpan(text: 'Blood ', style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
          TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFFE53935), fontSize: 32, fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
        ])),
      ],
    );
  }

  Widget _buildHeroIllustration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(width: 350, height: 350, decoration: BoxDecoration(color: Colors.red.withOpacity(0.02), shape: BoxShape.circle)),
              Image.asset('assets/image/blood_hand.png', height: 380, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.volunteer_activism, size: 200, color: Color(0xFFD9534F))),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text('Join Us.', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D), letterSpacing: -1)),
        const Text('Saves Lives.', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFD9534F), letterSpacing: -1)),
      ],
    );
  }

  Widget _buildRegisterCard() {
    bool isHospitalOrBank = _userType == 'Hospital' || _userType == 'Blood Bank';

    return Container(
      constraints: const BoxConstraints(maxWidth: 650),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
          const SizedBox(height: 40),
          
          _sectionHeader('I am a'),
          const SizedBox(height: 15),
          _buildUserTypeSelector(),
          const SizedBox(height: 35),

          _sectionHeader('Basic Information'),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildField(_fullNameController, isHospitalOrBank ? 'Institution Name' : 'Full Name', Icons.person_outline)),
              const SizedBox(width: 15),
              Expanded(child: _buildField(_usernameController, 'Username (Suggested)', Icons.alternate_email)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildField(
                _emailController, 
                'Enter Email', 
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
              )),
              const SizedBox(width: 15),
              Expanded(child: _buildField(
                _phoneController, 
                'Phone Number', 
                Icons.phone_outlined, 
                prefixText: '+880 ',
                errorText: _phoneError,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val.isNotEmpty && val.length < 10) {
                      _phoneError = "Please type valid phone number";
                    } else {
                      _phoneError = null;
                    }
                  });
                },
              )),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildField(_passwordController, 'Password', Icons.lock_outline, isPass: true, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword))),
              const SizedBox(width: 15),
              Expanded(child: _buildField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, isPass: true, obscure: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword))),
            ],
          ),

          const SizedBox(height: 25),
          _sectionHeader('Specific Details'),
          const SizedBox(height: 15),
          
          if (!isHospitalOrBank) ...[
            _buildDropdown('Select Blood Group', _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v)),
            const SizedBox(height: 15),
            _buildField(
              _nidController, 
              'NID Number (10 Digits)', 
              Icons.badge_outlined,
              errorText: _nidError,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (val) {
                setState(() {
                  if (val.isNotEmpty && val.length < 10) {
                    _nidError = "Please type valid nid number";
                  } else {
                    _nidError = null;
                  }
                });
              },
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 5),
              child: Text(
                'Please upload NID picture, otherwise you are not verified',
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            _buildImageUploadBox('Upload NID Picture (Optional)', _isNidUploaded, _pickNidImage),
          ] else ...[
            _buildField(_licenseController, 'License / Registration Number', Icons.assignment_outlined),
            const SizedBox(height: 15),
            _buildField(_additionalNotesController, 'Facilities / Institution Details', Icons.notes_outlined, maxLines: 3),
          ],

          const SizedBox(height: 25),
          _sectionHeader('Location Details'),
          const SizedBox(height: 15),
          _buildLocationSection(),
          
          const SizedBox(height: 35),
          Row(
            children: [
              Checkbox(value: _agreeToTerms, onChanged: (v) => setState(() => _agreeToTerms = v!), activeColor: const Color(0xFFE53935)),
              const Text('I agree to the ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Text('Terms & Policy', style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    List<String> districts = _selectedDivision != null ? (_districtsMap[_selectedDivision] ?? []) : [];
    bool isDhakaDistrict = _selectedDistrict == 'Dhaka';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdown('Division', _divisions, _selectedDivision, (v) => setState(() { _selectedDivision = v; _selectedDistrict = null; _selectedCityCorp = null; _selectedArea = null; }))),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdown('District', districts, _selectedDistrict, (v) => setState(() { _selectedDistrict = v; _selectedCityCorp = null; _selectedArea = null; }))),
          ],
        ),
        if (isDhakaDistrict) ...[
          const SizedBox(height: 15),
          _buildDropdown('City Corporation', _dhakaCityCorps.keys.toList(), _selectedCityCorp, (v) => setState(() { _selectedCityCorp = v; _selectedArea = null; })),
        ],
        if (_selectedDistrict != null && (!isDhakaDistrict || _selectedCityCorp != null)) ...[
          const SizedBox(height: 15),
          _buildDropdown('Select Area', isDhakaDistrict ? (_dhakaCityCorps[_selectedCityCorp] ?? []) : [], _selectedArea, (v) => setState(() => _selectedArea = v)),
        ],
      ],
    );
  }

  Widget _buildUserTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _userTypeBtn('Blood Donor', Icons.person),
          const SizedBox(width: 10),
          _userTypeBtn('Blood Seeker', Icons.search),
          const SizedBox(width: 10),
          _userTypeBtn('Hospital', Icons.local_hospital),
          const SizedBox(width: 10),
          _userTypeBtn('Blood Bank', Icons.opacity),
        ],
      ),
    );
  }

  Widget _userTypeBtn(String type, IconData icon) {
    bool isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() { _userType = type; }),
      child: Container(
        width: 110, padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCEBEB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFE53935) : const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFE53935) : Colors.black26),
            const SizedBox(height: 8),
            Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFE53935) : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)));

  Widget _buildField(TextEditingController c, String h, IconData i, {bool isPass = false, bool obscure = false, VoidCallback? onToggle, int maxLines = 1, Widget? suffix, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? errorText, Function(String)? onChanged, String? prefixText}) {
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
            controller: c, obscureText: isPass && obscure, maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Icon(i, color: Colors.black26, size: 18),
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
              hintText: h, hintStyle: const TextStyle(fontSize: 13, color: Colors.black26, fontWeight: FontWeight.bold),
              suffixIcon: suffix ?? (isPass ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.black26, size: 18), onPressed: onToggle) : null),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
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

  Widget _buildDropdown(String h, List<String> items, String? v, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: v, hint: Text(h, style: const TextStyle(fontSize: 13, color: Colors.black26, fontWeight: FontWeight.bold)),
          isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black26),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildImageUploadBox(String hint, bool uploaded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: uploaded ? Colors.green.shade200 : const Color(0xFFE5E7EB))),
        child: Row(
          children: [
            Icon(uploaded ? Icons.check_circle : Icons.cloud_upload_outlined, color: uploaded ? Colors.green : Colors.black26, size: 20),
            const SizedBox(width: 12),
            Text(uploaded ? 'NID Picture Uploaded' : hint, style: TextStyle(fontSize: 13, color: uploaded ? Colors.green : Colors.black26, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
