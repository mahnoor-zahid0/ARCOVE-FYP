import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase storage for image uploads
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:image_picker/image_picker.dart'; // Image picker for profile and certification
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import '../../main.dart'; // For navigation to HomePage

class ProfessionalSignUpPage extends StatefulWidget {
  const ProfessionalSignUpPage({Key? key}) : super(key: key);

  @override
  _ProfessionalSignUpPageState createState() => _ProfessionalSignUpPageState();
}

class _ProfessionalSignUpPageState extends State<ProfessionalSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _certificationIdController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _profileImage;
  File? _certificationImage;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to handle Professional Registration
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create user with email and password
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String userId = userCredential.user!.uid;
        String userName = _nameController.text.trim(); // Name as subfolder
        String userEmail = _emailController.text.trim(); // Email as parent folder

        // Sanitize user name for storage (to avoid special characters)
        String sanitizedUserName = Uri.encodeComponent(userName);

        // Folder path: Professionals/{userEmail}/{userName}/
        String folderPath = 'Professionals/$userEmail/$sanitizedUserName/';

        // Upload profile image and certification image
        if (_profileImage != null && _certificationImage != null) {
          final profileRef = _storage.ref().child('$folderPath/profile.jpg');
          final certificationRef = _storage.ref().child('$folderPath/certification.jpg');

          await profileRef.putFile(_profileImage!);
          await certificationRef.putFile(_certificationImage!);

          // Get download URLs for uploaded images
          final profileImageUrl = await profileRef.getDownloadURL();
          final certificationImageUrl = await certificationRef.getDownloadURL();

          // Store professional details in Firestore
          await _firestore.collection('professionals').doc(userId).set({
            'name': userName,
            'email': userEmail,
            'certificationId': _certificationIdController.text,
            'profileImage': profileImageUrl,
            'certificationImage': certificationImageUrl,
            'description': _descriptionController.text,
            'createdAt': Timestamp.now(),
          });

          // Save login state locally using SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', userName);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully! Please wait for approval.')),
          );

          // Redirect to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(isLoggedIn: true, userName: userName)),
          );
        } else {
          setState(() {
            _errorMessage = "Please upload both profile and certification images.";
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  // Picking profile image
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Picking certification image
  Future<void> _pickCertificationImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _certificationImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildWelcomeSection(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _buildSignupForm(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Background for the signup page
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB46146), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // Welcome section for the signup page
  Widget _buildWelcomeSection() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Text(
        'Become a Professional!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Signup form layout
  Widget _buildSignupForm(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Professional Sign Up',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),
            _buildTextField(_nameController, 'Name', validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            }),
            const SizedBox(height: 20.0),
            _buildTextField(_emailController, 'Email', validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            }),
            const SizedBox(height: 20.0),
            _buildTextField(_passwordController, 'Password', obscureText: true, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              } else if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            }),
            const SizedBox(height: 20.0),
            _buildTextField(_confirmPasswordController, 'Confirm Password', obscureText: true, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              } else if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            }),
            const SizedBox(height: 20.0),
            _buildTextField(_certificationIdController, 'Certification ID', validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your Certification ID';
              }
              return null;
            }),
            const SizedBox(height: 20.0),
            _buildTextField(_descriptionController, 'Description', validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide a description of yourself';
              }
              return null;
            }),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: _profileImage == null
                      ? const Text(
                    'Upload Profile Image',
                    style: TextStyle(color: Colors.grey),
                  )
                      : Image.file(
                    _profileImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: _pickCertificationImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: _certificationImage == null
                      ? const Text(
                    'Upload Certification Image',
                    style: TextStyle(color: Colors.grey),
                  )
                      : Image.file(
                    _certificationImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB46146),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'After signing up, please wait for up to 24 hours for approval.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'Already have an account? Login!',
                style: TextStyle(
                  color: Colors.pink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build text fields
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, required String? Function(dynamic value) validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
