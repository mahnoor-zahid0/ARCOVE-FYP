import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sample/PROFESSIONAL/profile.dart';
import 'package:sample/PROFESSIONAL/search/search_home.dart';
import 'package:sample/PROFESSIONAL/upload_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../main.dart'; // Assuming HomePage is defined in main.dart
import '../setting.dart';
import 'message/message_home.dart';

class ProfessionalHomePage extends StatefulWidget {
  @override
  _ProfessionalHomePageState createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
  int _selectedIndex = 0;
  String? profileImageUrl;
  String? professionalName;

  final List<Widget> _pages = [
    ProHomePage(),
    SearchPage(),
    UploadPage(),
    ProfessionalProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Fetch professional name and profile image from Firebase Firestore
  Future<void> _fetchProfileData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email!;

      // Fetch professional data from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('professionals').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          professionalName = doc['name'];
        });

        // Fetch profile image from Firebase Storage
        try {
          final storageRef = FirebaseStorage.instance.ref().child('Professionals/$userEmail/profile.jpg');
          String imageUrl = await storageRef.getDownloadURL();
          setState(() {
            profileImageUrl = imageUrl;
          });
        } catch (e) {
          print('Error fetching profile image: $e');
        }
      }
    }
  }

  // Handle bottom navigation item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout functionality
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved session data
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase

    // Navigate to HomePage after logout
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SplashScreen()), // Navigate to HomePage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB46146),
        title: const Text(
          'Professionals',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagesPage()
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFB46146),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage('assets/placeholder_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    professionalName ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsMainPage(isLoggedIn: false,)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsMainPage(isLoggedIn: true,)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout, // Call logout function when tapped
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProHomePage extends StatefulWidget {
  @override
  _ProHomePageState createState() => _ProHomePageState();
}

class _ProHomePageState extends State<ProHomePage> {
  List<Map<String, dynamic>> postData = [];
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchPosts(); // Fetch posts and user data on initialization
  }

  // Fetch post images and user data from Firestore and Firebase Storage
  Future<void> fetchPosts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('professionals').get();
      List<Map<String, dynamic>> fetchedData = [];

      for (var doc in querySnapshot.docs) {
        String userEmail = doc['email'];
        String userName = doc['name'];

        // Fetch all images from 'Uploads' folder in Firebase Storage
        final ListResult result = await FirebaseStorage.instance
            .ref('Professionals/$userEmail/Uploads/Posts')
            .listAll();

        for (var fileRef in result.items) {
          String imageUrl = await fileRef.getDownloadURL();
          fetchedData.add({
            'userName': userName,
            'description': doc['bio'] ?? 'No description available',
            'imageUrl': imageUrl,
          });
        }
      }

      setState(() {
        postData = fetchedData;
        isLoading = false; // Stop showing the loading indicator
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        isLoading = false; // Stop showing the loading indicator even on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: isLoading ? 5 : postData.length,
                itemBuilder: (context, index) {
                  if (isLoading) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 50,
                            height: 10,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.orange,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(postData[index]['imageUrl']),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          postData[index]['userName'],
                          style: const TextStyle(
                            color: Color(0xFFB46146),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.grey),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: isLoading ? 5 : postData.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          title: Container(
                            width: 100,
                            height: 10,
                            color: Colors.grey[300],
                          ),
                          subtitle: Container(
                            width: 80,
                            height: 8,
                            color: Colors.grey[200],
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Container(
                            width: double.infinity,
                            height: 10,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return PostCard(
                  userName: postData[index]['userName'],
                  description: postData[index]['description'],
                  imageUrl: postData[index]['imageUrl'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String userName;
  final String description;
  final String imageUrl;

  const PostCard({
    required this.userName,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            title: Text(userName, style: const TextStyle(color: Color(0xFFB46146))),
            subtitle: const Text('3 d', style: TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {},
            ),
          ),
          AspectRatio(
            aspectRatio: 3 / 3,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color(0xFFB46146),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Upload'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
