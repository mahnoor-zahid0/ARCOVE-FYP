import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:path/path.dart';
import 'package:sample/PROFESSIONAL/profile.dart'; // For getting file name

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _selectedImage; // Store the selected media file
  final ImagePicker _picker = ImagePicker();
  List<File> _galleryImages = []; // Store multiple gallery images (for the demo)

  // Function to pick image from gallery
  Future<void> _pickMedia() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Store the selected file
        _galleryImages.add(File(pickedFile.path));
      });
    }
  }

  // Function to navigate to the PostDetailsPage
  void _goToNextPage() {
    if (_selectedImage != null) {
      Navigator.push(
        context as BuildContext, // No need for casting context
        MaterialPageRoute(
          builder: (context) => PostDetailsPage(imageFile: _selectedImage!, onShare: _shareImage),
        ),
      );
    }
  }

  // Function to share the image (move to profile page)
  void _shareImage(File image) {
    setState(() {
      _galleryImages.add(image); // Add the shared image to gallery list for profile
    });
    Navigator.pop(context as BuildContext); // Go back to the UploadPage
    Navigator.push(
      context as BuildContext,
      MaterialPageRoute(builder: (context) => ProfessionalProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background is white now
      appBar: AppBar(
        title: const Text('New post', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFB46146),
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedImage != null) {
                // Navigate to PostDetailsPage with the selected image
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailsPage(
                      imageFile: _selectedImage!,
                      onShare: _shareImage,
                    ),
                  ),
                );
              } else {
                // Show a message if no image is selected
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an image first!')),
                );
              }
            },
            child: const Text(
              'Next',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedImage != null)
            Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.select_all, size: 20, color: Colors.white),
                    label: const Text('Select Multiple', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              height: 250,
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),

          const Divider(color: Colors.white),

          // Gallery images grid below the selected image
          Expanded(
            child: GridView.builder(
              itemCount: _galleryImages.length + 1, // Including the "select from gallery" button
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Number of images per row
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                // Show "Select from Gallery" as the first item
                if (index == 0) {
                  return GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.add_photo_alternate, color: Colors.white),
                    ),
                  );
                }
                // Show other gallery images
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = _galleryImages[index - 1]; // Update the selected image
                    });
                  },
                  child: Image.file(
                    _galleryImages[index - 1],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// New page where users can add caption and share
class PostDetailsPage extends StatefulWidget {
  final File imageFile;
  final Function(File) onShare;

  const PostDetailsPage({Key? key, required this.imageFile, required this.onShare}) : super(key: key);

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  // Function to upload image to Firebase Storage and save caption, timestamp to Firestore
  Future<void> _uploadImageToFirebase() async {
    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = basename(widget.imageFile.path); // Get file name
      User? user = FirebaseAuth.instance.currentUser; // Get logged-in user

      if (user == null) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text('User is not logged in!')),
        );
        return;
      }

      String userEmail = user.email ?? 'unknown'; // Get professional's email

      // Upload the image to Firebase Storage in the 'Uploads/Posts' subfolder
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('Professionals/$userEmail/Uploads/Posts/$fileName');
      await storageRef.putFile(widget.imageFile); // Upload image

      // Get the download URL of the uploaded image
      final downloadUrl = await storageRef.getDownloadURL();

      // Save the image URL, caption, and timestamp to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': downloadUrl,
        'caption': _captionController.text,
        'userId': user.uid,
        'userEmail': userEmail, // Storing user email
        'timestamp': FieldValue.serverTimestamp(), // Real-time timestamp
      });

      // Notify user of successful upload
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text('Image and caption uploaded successfully!')),
      );

      widget.onShare(widget.imageFile);

      // Navigate to ProfessionalProfilePage after successful upload
      Navigator.pushReplacement(
        context as BuildContext,
        MaterialPageRoute(
          builder: (context) => ProfessionalProfilePage(),
        ),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New post', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Image
              Image.file(widget.imageFile, height: 200, width: double.infinity, fit: BoxFit.cover),
              const SizedBox(height: 10),

              // Caption Input
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 20),

              // Share button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImageToFirebase,
                child: _isUploading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Share', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUploading ? Colors.grey : const Color(0xFFB46146),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
