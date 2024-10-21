import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clipboard/clipboard.dart';


import '../setting.dart'; // For copying profile links to the clipboard

class ProfessionalProfilePage extends StatefulWidget {
  @override
  _ProfessionalProfilePageState createState() => _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<String> uploadedImageUrls = [];
  int followersCount = 0;
  int followingCount = 0;
  int postCount = 0;
  String? profileImageUrl;
  String bio = '';
  String professionalName = '';

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchUploadedImages();
    _fetchFollowers();
    _fetchFollowing();
  }

  // Fetch profile data (profile image, bio, name)
  Future<void> _fetchProfileData() async {
    try {
      String userEmail = currentUser?.email ?? '';

      // Fetch the profile picture URL from Firebase Storage
      final profileImageRef = FirebaseStorage.instance
          .ref()
          .child('Professionals/$userEmail/profile.jpg');

      String profileImageUrlFetched = await profileImageRef.getDownloadURL();

      // Fetch profile data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(currentUser?.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          profileImageUrl = profileImageUrlFetched;
          bio = userDoc['bio'] ?? '';
          professionalName = userDoc['name'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  // Fetch uploaded images by the professional
  Future<void> _fetchUploadedImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: currentUser?.uid)
          .get();

      List<String> urls = snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();

      setState(() {
        uploadedImageUrls = urls;
        postCount = urls.length; // Update the post count
      });
    } catch (e) {
      print('Error fetching uploaded images: $e');
    }
  }

  // Fetch followers count
  Future<void> _fetchFollowers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(currentUser?.uid)
          .collection('followers')
          .get();

      setState(() {
        followersCount = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching followers: $e');
    }
  }

  // Fetch following count
  Future<void> _fetchFollowing() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(currentUser?.uid)
          .collection('following')
          .get();

      setState(() {
        followingCount = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching following: $e');
    }
  }

  // Share profile link
  void _shareProfile() {
    final profileLink = 'https://myapp.com/profile/${currentUser?.uid}'; // Placeholder for profile link
    Share.share('Check out my profile: $profileLink');
  }

  // Copy profile link to clipboard
  void _copyProfileLink() {
    final profileLink = 'https://myapp.com/profile/${currentUser?.uid}'; // Make sure currentUser is not null
    if (profileLink != null) {
      FlutterClipboard.copy(profileLink).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile link copied to clipboard!')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy the link')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate profile link')),
      );
    }
  }


  // Function to show list of followers/following
  void _showUserList(String title, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListPage(type: type), // Navigating to a new page
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB46146),
        title: Text(professionalName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professionalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatItem('$postCount', 'Posts'),
                          GestureDetector(
                            onTap: () => _showUserList('Followers', 'followers'),
                            child: _buildStatItem('$followersCount', 'Followers'),
                          ),
                          GestureDetector(
                            onTap: () => _showUserList('Following', 'following'),
                            child: _buildStatItem('$followingCount', 'Following'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bio Section
              Text(
                bio,
                style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),

              // Action Buttons (Edit Profile, Share, Copy Link)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to Edit Profile Page
    /*Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(),
                          ),
                        );*/
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB46146),
                      ),
                      child: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _copyProfileLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB46146),
                      ),
                      child: const Text('Copy Profile Link', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Share Profile Button
              ElevatedButton(
                onPressed: _shareProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB46146),
                ),
                child: const Text('Share Profile', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // Posts Section
              uploadedImageUrls.isEmpty
                  ? const Center(child: Text('No posts yet', style: TextStyle(fontSize: 18)))
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uploadedImageUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      uploadedImageUrls[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function for building statistics items
  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }
}

// User List Page (followers or following list)
class UserListPage extends StatelessWidget {
  final String type; // 'followers' or 'following'

  const UserListPage({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB46146),
        title: Text(type == 'followers' ? 'Followers' : 'Following'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('professionals')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection(type)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
              );
            },
          );
        },
      ),
    );
  }
}
