import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample/professional.dart';
import 'package:sample/property.dart';
import 'package:sample/realistic_design_visualization.dart';
import 'package:sample/renovation_ideas.dart';
import 'package:sample/saved_page.dart';
import 'package:sample/setting.dart';
import 'package:sample/trending.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'PROFESSIONAL/Pro_signup/pro_signup.dart';
import 'PROFESSIONAL/professional_home_page.dart';
import 'design_catalog.dart';
import 'message_consultation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 3), _navigateToHome);
  }

  void _navigateToHome() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    bool? isProfessional = prefs.getBool('isProfessional');

    if (isLoggedIn == true) {
      if (isProfessional == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ProfessionalHomePage()),
        );
      } else {
        String? userName = prefs.getString('userName');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => HomePage(isLoggedIn: true, userName: userName)),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage(isLoggedIn: false)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Image(
                image: AssetImage('assets/logo/logo.png'),
                width: 150,
                height: 150,
              ),
              SizedBox(height: 20),
              Text(
                'Find, connect, move in',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB46146),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// HomePage for logged in or guest users
class HomePage extends StatefulWidget {
  final bool isLoggedIn;
  final String? userName;

  const HomePage({Key? key, required this.isLoggedIn, this.userName}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController1 = PageController(viewportFraction: 0.8);
  Timer? _timer1;
  int _selectedIndex = 0;
  String? userName;
  bool isLoggedIn = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    userName = widget.userName;
    if (isLoggedIn) {
      _fetchUserProfile();
    }
    _timer1 = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController1.page == 4) {
        _pageController1.animateToPage(
            0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      } else {
        _pageController1.nextPage(
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String? profileImageUrl = userDoc.get('profileImageUrl');

        setState(() {
          userName = userDoc.get('name') ?? 'User';
          _profileImageUrl = profileImageUrl ?? 'https://via.placeholder.com/150';
        });
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  @override
  void dispose() {
    _pageController1.dispose();
    _timer1?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    FirebaseAuth.instance.signOut();
    setState(() {
      isLoggedIn = false;
      userName = null;
      _profileImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'ARCOVE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB46146),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text('Sign up', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildPromoSection(),
              const SizedBox(height: 20),
              const Text(
                'The world’s destination\nfor design',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Get inspired by the work of millions of top-rated designers & agencies around the world.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              if (!isLoggedIn)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB46146),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _buildPageView(),
              const SizedBox(height: 20),
              _buildHorizontalScrollSection(),
              const SizedBox(height: 20),
              exploreMoreSection(),
              const SizedBox(height: 20),
              exploreInspiringDesigns(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFB46146),
            ),
            accountName: Text(
              userName ?? 'Guest',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              isLoggedIn ? FirebaseAuth.instance.currentUser?.email ?? '' : 'Not logged in',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
              child: _profileImageUrl == null ? const Icon(Icons.person, size: 30) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsMainPage(isLoggedIn: false,)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Saved'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedPage()),
              );
            },
          ),
          if (!isLoggedIn) // Add Become a Professional option for non-logged-in users
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Become a Professional'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfessionalSignUpPage()), // Link to the Professional sign-up page
                );
              },
            ),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: const Text(
        'Over 3 million ready-to-work creatives!',
        style: TextStyle(
          color: Color(0xFFB46146),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return SizedBox(
      height: 150,
      child: PageView(
        controller: _pageController1,
        children: [
          featureContainer(context, 'Design Catalog', Icons.design_services,
              const DesignCatalogPage()),
          featureContainer(context, 'Professional Consultation', Icons.business,
              ProfessionalPage()),
          featureContainer(context, 'Property', Icons.person,
              PropertyPage()),
          featureContainer(context, 'Renovation Ideas', Icons.lightbulb,
              RenovationsPage()),
        ],
      ),
    );
  }

  Widget featureContainer(BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFB46146),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          featureCardButton('Interior Designing', Icons.home, () {}),
          featureCardButton('Exterior Designing', Icons.landscape, () {}),
        ],
      ),
    );
  }

  Widget featureCardButton(String title, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFB46146),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget exploreMoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Explore More',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrendingPage()),
                );
              },
              child: const Row(
                children: [
                  Text('See All', style: TextStyle(color: Color(0xFFB46146))),
                  Icon(Icons.arrow_right, color: Color(0xFFB46146)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchImagesFromFirebase(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.grey[300],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading data'),
              );
            }

            final images = snapshot.data ?? [];
            return SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  var image = images[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                      image: DecorationImage(
                        image: NetworkImage(image['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              image['title'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Designer: ${image['designer']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Likes: ${image['likes']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Views: ${image['views']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> fetchImagesFromFirebase() async {
    List<Map<String, dynamic>> imageList = [];
    try {
      final ListResult result = await FirebaseStorage.instance
          .ref()
          .child('RENOVATION/NEW HOME/')
          .listAll();
      for (var ref in result.items) {
        final imageUrl = await ref.getDownloadURL();
        imageList.add({
          'imageUrl': imageUrl,
          'title': 'Sample Title',
          'designer': 'Sample Designer',
          'likes': 10,
          'views': 100,
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
    }
    return imageList;
  }

  Widget exploreInspiringDesigns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Explore inspiring designs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchImagesFromOutlooksFolder(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.grey[300],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading data'),
              );
            }

            final images = snapshot.data ?? [];
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                var image = images[index];
                return ExploreMoreImage(
                  imageUrl: image['imageUrl'],
                  title: image['title'],
                  designer: image['designer'],
                  status: image['status'],
                  likes: image['likes'].toString(),
                  views: image['views'].toString(),
                  onLike: () {
                    // Implement like functionality if needed
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),
        reviewAndRatingsSection(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> fetchImagesFromOutlooksFolder() async {
    List<Map<String, dynamic>> imageList = [];
    try {
      final ListResult result = await FirebaseStorage.instance
          .ref()
          .child('RENOVATION/OUTLOOKS/')
          .listAll();

      for (var ref in result.items) {
        final imageUrl = await ref.getDownloadURL();
        imageList.add({
          'imageUrl': imageUrl,
          'title': 'Sample Title',
          'designer': 'Sample Designer',
          'status': 'Completed',
          'likes': 10,
          'views': 100,
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
    }
    return imageList;
  }
}

class ExploreMoreImage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String designer;
  final String status;
  final String likes;
  final String views;
  final VoidCallback onLike;

  const ExploreMoreImage({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.designer,
    required this.status,
    required this.likes,
    required this.views,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      width: 150.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  designer,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Likes: $likes',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Views: $views',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.white),
                  onPressed: onLike,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget reviewAndRatingsSection() {
  List<Map<String, dynamic>> reviews = [
    {
      'name': 'John Doe',
      'review': 'Amazing design! Really helped me visualize my space.',
      'rating': 4.5,
    },
    {
      'name': 'Jane Smith',
      'review': 'Great work by the designer. Very detailed.',
      'rating': 4.0,
    },
    {
      'name': 'Michael Johnson',
      'review': 'The designs are very professional. Highly recommend!',
      'rating': 5.0,
    },
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text(
        'Customer Reviews & Ratings',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          var review = reviews[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review['review'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    Text(
                      review['rating'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      color: review['rating'] >= 1 ? Colors.yellow : Colors.grey,
                      size: 16,
                    ),
                    Icon(
                      Icons.star,
                      color: review['rating'] >= 2 ? Colors.yellow : Colors.grey,
                      size: 16,
                    ),
                    Icon(
                      Icons.star,
                      color: review['rating'] >= 3 ? Colors.yellow : Colors.grey,
                      size: 16,
                    ),
                    Icon(
                      Icons.star,
                      color: review['rating'] >= 4 ? Colors.yellow : Colors.grey,
                      size: 16,
                    ),
                    Icon(
                      Icons.star_half,
                      color: review['rating'] == 4.5 ? Colors.yellow : Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          onTap(index);

          // Navigate to the corresponding page when an icon is clicked
          if (index == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const HomePage(isLoggedIn: true, userName: "User"))); // Navigate to HomePage
          } else if (index == 1) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => TrendingPage())); // Navigate to TrendingPage
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const RealisticDesignVisualization())); // Navigate to AR Page
          } else if (index == 3) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => const ConsultPage())); // Navigate to ConsultPage
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsMainPage(isLoggedIn: true,)),
            ); // Navigate to SettingsPage
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        selectedItemColor: const Color(0xFFB46146),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(color: Color(0xFFB46146)),
        unselectedLabelStyle: const TextStyle(color: Colors.grey),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.home, 0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.whatshot, 1),
            label: 'Trending',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.view_in_ar, 2),
            label: 'AR',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.message_outlined, 3),
            label: 'Consult',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.settings, 4),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(top: currentIndex == index ? 0 : 10),
      child: Icon(
        icon,
        size: currentIndex == index ? 30 : 24,
        color: currentIndex == index ? const Color(0xFFB46146) : Colors.grey,
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;

  const PlaceholderWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Text('This is a placeholder page'),
      ),
    );
  }
}


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  File? _selectedImage; // File to hold the selected image
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Function to handle image selection from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Function to upload the image to Firebase Storage
  Future<String?> _uploadImageToFirebase(String userName) async {
    if (_selectedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('users/$userName/profile.jpg');
      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with email and password
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final User? user = userCredential.user;
        if (user != null) {
          // Upload profile image if selected
          String? profileImageUrl;
          if (_selectedImage != null) {
            profileImageUrl = await _uploadImageToFirebase(_nameController.text.trim());
          }

          // Save user data to Firestore in a folder named by their username
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'profileImageUrl': profileImageUrl ?? '',
          });

          // Store the login state and username in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', _nameController.text.trim());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );

          // Navigate to the home page after successful signup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(isLoggedIn: true, userName: _nameController.text)),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
          if (_isLoading) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
          ]
        ],
      ),
    );
  }

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

  Widget _buildWelcomeSection() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Text(
        'Welcome!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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
              'Sign up',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),

            // Profile Image Section
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                child: _selectedImage == null ? const Icon(Icons.add_a_photo, size: 50) : null,
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
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
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

  // Function to show the image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a picture'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  // Function to handle login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Authenticate with Firebase using email and password
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Fetch user email
        String userEmail = _emailController.text.trim();

        // Check if the user is a professional by checking if their folder exists in Firebase Storage
        bool isProfessional = await _checkIfProfessional(userEmail);

        // Save login status and user information to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', _emailController.text.split('@')[0]);

        // Navigate to the respective homepage based on user type
        if (isProfessional) {
          // User is a professional, navigate to ProfessionalHomePage
          await prefs.setBool('isProfessional', true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfessionalHomePage()),
          );
        } else {
          // User is a regular user, navigate to HomePage
          await prefs.setBool('isProfessional', false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage(isLoggedIn: true)),
          );
        }
      } catch (e) {
        // Display an error message if login fails
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  // Function to check if the user is a professional by checking Firebase Storage folder
  Future<bool> _checkIfProfessional(String userEmail) async {
    try {
      // Check for folder in Firebase Storage with the user's email in the Professionals folder
      final storageRef = FirebaseStorage.instance.ref().child('Professionals/$userEmail/');
      final listResult = await storageRef.listAll();
      return listResult.items.isNotEmpty || listResult.prefixes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Function to handle password reset
  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email to reset the password';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'Error sending reset email')),
      );
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
                  _buildLoginForm(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build background decoration
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

  // Build welcome section
  Widget _buildWelcomeSection() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Text(
        'Welcome Back!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Build the login form
  Widget _buildLoginForm(BuildContext context) {
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
              'Login',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              _emailController,
              'Email',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            _buildTextField(
              _passwordController,
              'Password',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 10.0),
            GestureDetector(
              onTap: _sendPasswordResetEmail,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFFB46146),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB46146),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
              },
              child: const Text(
                'Don\'t have an account? Sign Up!',
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

  // Build text field
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
