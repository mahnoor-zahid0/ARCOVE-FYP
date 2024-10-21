import 'package:flutter/material.dart';
import 'package:sample/saved_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert'; // For JSON encoding and decoding

// Import your pages here
import 'exterior.dart';
import 'home_designs.dart';
import 'interior_designs.dart';
import 'main.dart';

class DesignCatalogPage extends StatefulWidget {
  const DesignCatalogPage({super.key});

  @override
  _DesignCatalogPageState createState() => _DesignCatalogPageState();
}

class _DesignCatalogPageState extends State<DesignCatalogPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  bool isLoggedIn = false;
  Map<String, List<Map<String, String>>> folderImages = {}; // A map to hold folder names, image URLs, and titles
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, String>> savedImages = []; // List to store saved images

  @override
  bool get wantKeepAlive => true; // Ensure page state is preserved

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSavedImages(); // Load saved images from SharedPreferences
    _fetchImagesFromFirebase();
  }

  // Check the login status of the user
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  // Fetch images from Firebase Storage for each folder
  Future<void> _fetchImagesFromFirebase() async {
    final storageRef = FirebaseStorage.instance.ref().child('RENOVATION/');
    List<String> folders = ['BEDROOMS', 'BUILDINGS', 'KITCHEN', 'OFFICES', 'OUTLOOKS'];

    try {
      Map<String, List<Map<String, String>>> tempFolderImages = {};
      for (String folder in folders) {
        final folderRef = storageRef.child('$folder/');
        ListResult result = await folderRef.listAll();

        List<Map<String, String>> images = [];
        for (var ref in result.items) {
          String downloadUrl = await ref.getDownloadURL();
          String imageName = ref.name; // Extract image name from Firebase
          images.add({
            'url': downloadUrl,
            'title': imageName, // Store the image title (name from Firebase)
          });
        }

        tempFolderImages[folder] = images; // Save the images under the corresponding folder
      }

      setState(() {
        folderImages = tempFolderImages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // Load saved images from SharedPreferences
  Future<void> _loadSavedImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedImagesJson = prefs.getString('saved_images');
    if (savedImagesJson != null) {
      setState(() {
        savedImages = List<Map<String, String>>.from(json.decode(savedImagesJson));
      });
    }
  }

  // Save image to SharedPreferences
  Future<void> _saveImageToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedImagesJson = json.encode(savedImages);
    prefs.setString('saved_images', savedImagesJson);
  }

  // Function to save or show sign-up prompt
  void _onImageTap(BuildContext context, String imageUrl, String imageTitle) {
    if (!isLoggedIn) {
      _showSignUpPrompt(context);
    } else {
      _saveImage(imageUrl, imageTitle);
    }
  }

  // Show a sign-up prompt
  void _showSignUpPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Up Required'),
        content: const Text('You need to sign up or log in to save images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpPage()),
              );
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  // Save image to the list and persist in SharedPreferences
  void _saveImage(String imageUrl, String imageTitle) {
    setState(() {
      savedImages.add({
        'url': imageUrl,
        'title': imageTitle,
      });
      _saveImageToPreferences();
    });
  }

  // Remove saved image from the list and update SharedPreferences
  void _removeImage(String imageUrl) {
    setState(() {
      savedImages.removeWhere((image) => image['url'] == imageUrl);
      _saveImageToPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Design Catalog',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
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
                child: const Text('Sign up'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              // Navigate to SavePage and pass savedImages
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: const Text(
          'Error loading images. Please try again later.',
          style: TextStyle(color: Colors.red),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  hintText: 'Search designs...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Trending Searches Title
              const Text(
                'Trending Searches',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ListView of Feature Cards
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    featureCard('Home', Icons.home, context, const HomeGridPage()),
                    featureCard('Offices', Icons.business, context, const HomeGridPage()),
                    featureCard('Interior', Icons.bed, context, const InteriorDesignPage()),
                    featureCard('Exterior', Icons.landscape, context, const ExteriorDesignPage()),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Show the images folder by folder
              for (String folderName in folderImages.keys)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Folder Name as the title for each section
                    Text(
                      folderName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Display images for the current folder in a grid
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: folderImages[folderName]!.length,
                      itemBuilder: (context, index) {
                        String imageUrl = folderImages[folderName]![index]['url']!;
                        String imageTitle = folderImages[folderName]![index]['title']!;
                        return GestureDetector(
                          onTap: () {
                            _onImageTap(context, imageUrl, imageTitle);
                          },
                          child: exploreMoreImageGrid(imageUrl, imageTitle),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget featureCard(String title, IconData icon, BuildContext context, Widget destinationPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.brown),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget exploreMoreImageGrid(String imageUrl, String imageTitle) {
    return Column(
      children: [
        Expanded(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          imageTitle, // Show the image title under the image
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        IconButton(
          icon: const Icon(Icons.bookmark_add),
          onPressed: () {
            _onImageTap(context, imageUrl, imageTitle);
          },
        ),
      ],
    );
  }
}

class SavePage extends StatelessWidget {
  final List<Map<String, String>> savedImages;

  const SavePage({super.key, required this.savedImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Images'),
      ),
      body: savedImages.isEmpty
          ? const Center(child: Text('No saved images yet.'))
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: savedImages.length,
        itemBuilder: (context, index) {
          String imageUrl = savedImages[index]['url']!;
          String imageTitle = savedImages[index]['title']!;
          return GestureDetector(
            onLongPress: () {
              // Option to remove image
              _removeSavedImage(context, imageUrl);
            },
            child: exploreMoreImageGrid(imageUrl, imageTitle),
          );
        },
      ),
    );
  }

  // Remove image from saved list
  void _removeSavedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image from saved list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // You will need to implement the remove logic here
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

Widget exploreMoreImageGrid(String imageUrl, String imageTitle) {
  return Column(
    children: [
      Expanded(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error, color: Colors.red);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      const SizedBox(height: 8),
      Text(
        imageTitle, // Show the image title under the image
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
    ],
  );
}
