import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

import 'main.dart';

class TrendingPage extends StatefulWidget {
  @override
  _TrendingPageState createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  int _selectedIndex = 1;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  List<Map<String, dynamic>> trendingImages = [];
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> professionals = []; // For storing professionals
  bool _isLoading = true;
  bool isLoggedIn = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadState();
    _checkLoginStatus();
    _fetchProfessionals(); // Fetch professionals from Firebase
  }

  // Check if user is logged in
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  // Load state from SharedPreferences
  Future<void> _loadState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load trending images
    String? savedImagesData = prefs.getString('trendingImages');
    if (savedImagesData != null) {
      List<Map<String, dynamic>> savedImages =
      List<Map<String, dynamic>>.from(json.decode(savedImagesData));
      setState(() {
        trendingImages = savedImages;
        _isLoading = false;
      });
    } else {
      _fetchTrendingImages();
    }

    // Load saved suggestions
    String? savedSuggestionsData = prefs.getString('suggestions');
    if (savedSuggestionsData != null) {
      List<Map<String, dynamic>> savedSuggestions =
      List<Map<String, dynamic>>.from(json.decode(savedSuggestionsData));
      setState(() {
        suggestions = savedSuggestions;
      });
    }
  }

  // Fetch professionals from Firebase Firestore
  Future<void> _fetchProfessionals() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('professionals').get();
      List<Map<String, dynamic>> fetchedProfessionals = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'profilePic': doc['profilePic'],
          'specialty': doc['specialty'] ?? 'Unknown',
        };
      }).toList();

      setState(() {
        professionals = fetchedProfessionals;
      });
    } catch (e) {
      print('Error fetching professionals: $e');
    }
  }

  // Fetch trending images from Firebase Storage
  Future<void> _fetchTrendingImages() async {
    try {
      List<Map<String, dynamic>> fetchedImages = [];
      List<String> folders = [
        'BEDROOMS',
        'BUILDINGS',
        'Bathroom',
        'KITCHEN',
        'NEW HOME',
        'OFFICES',
        'OUTLOOKS',
        'PROPERTY',
      ];

      for (String folder in folders) {
        final ListResult result = await _storage.ref('RENOVATION/$folder').listAll();
        for (var ref in result.items) {
          final imageUrl = await ref.getDownloadURL();
          fetchedImages.add({'path': imageUrl, 'title': ref.name});
        }
      }

      setState(() {
        trendingImages = fetchedImages;
        _isLoading = false;
      });

      _saveState(); // Save the state after fetching
    } catch (error) {
      print('Error fetching trending images: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save state to SharedPreferences
  Future<void> _saveState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save trending images
    await prefs.setString('trendingImages', json.encode(trendingImages));

    // Save suggestions
    await prefs.setString('suggestions', json.encode(suggestions));
  }

  // Fetch suggestions based on the search query
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    List<Map<String, dynamic>> allSuggestions = [];

    // Query professionals from Firestore
    QuerySnapshot professionalSnapshot = await _firestore
        .collection('professionals')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    List<Map<String, dynamic>> professionalSuggestions = professionalSnapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc['name'], 'type': 'professional'};
    }).toList();

    // Query images from the trending list
    List<Map<String, dynamic>> imageSuggestions = trendingImages
        .where((image) => image['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    allSuggestions = [...professionalSuggestions, ...imageSuggestions];

    setState(() {
      suggestions = allSuggestions;
    });

    _saveState(); // Save suggestions
  }

  // Perform search query
  void _performSearch(String query) {
    if (query.isEmpty) return;

    // Filter trendingImages based on the search query
    List<Map<String, dynamic>> imageResults = trendingImages.where((image) {
      return image['title'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      trendingImages = imageResults;
    });
  }

  // Handle professional container click
  void _handleProfessionalContainerClick(BuildContext context) {
    if (isLoggedIn) {
      print('User is logged in: Show professional details');
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
    }
  }

  // Determine whether to show an ad
  bool _shouldShowAd(int index) {
    return _random.nextInt(10) == 0; // Show ad every 10 items
  }

  // Handle bottom navigation tap
  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search professionals or images',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.black54),
          ),
          onChanged: (query) {
            searchQuery = query;
            _fetchSuggestions(query);
          },
          onSubmitted: (query) {
            _performSearch(query);
          },
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : suggestions.isNotEmpty || searchQuery.isNotEmpty
          ? _buildSuggestionsList()
          : _buildTrendingGrid(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // Build suggestions list based on search query
  Widget _buildSuggestionsList() {
    if (suggestions.isEmpty && searchQuery.isNotEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          title: Text(suggestion['type'] == 'professional'
              ? 'Professional: ${suggestion['name']}'
              : 'Design: ${suggestion['title']}'),
          onTap: () {
            // Handle navigation or interaction here
          },
        );
      },
    );
  }

  // Build trending grid with optional ads
  Widget _buildTrendingGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75, // Ratio for image size
        ),
        itemCount: trendingImages.length + (trendingImages.length ~/ 5), // Account for ads
        itemBuilder: (context, index) {
          if (_shouldShowAd(index)) {
            return GestureDetector(
              onTap: () => _handleProfessionalContainerClick(context),
              child: ProfessionalAdContainer(professional: professionals[_random.nextInt(professionals.length)]),
            );
          }

          final actualIndex = index - (index ~/ 5);
          if (actualIndex >= trendingImages.length) return Container(); // Avoid index errors

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey), // Add border to grid box
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: TrendingTile(
              imagePath: trendingImages[actualIndex]['path'] ?? '',
              title: trendingImages[actualIndex]['title'] ?? '',
            ),
          );
        },
      ),
    );
  }
}

// Widget for each trending image tile
class TrendingTile extends StatelessWidget {
  final String imagePath;
  final String title;

  const TrendingTile({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
            child: Image.network(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// Widget for professional ad containers
class ProfessionalAdContainer extends StatelessWidget {
  final Map<String, dynamic> professional;

  const ProfessionalAdContainer({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orangeAccent.shade100,
        border: Border.all(color: Colors.grey), // Add border to ad container
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.network(
              professional['profilePic'] ?? 'assets/placeholder.png',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${professional['name']} - ${professional['specialty']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Contact for professional design consultations',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {}, // Add your logic
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }
}
