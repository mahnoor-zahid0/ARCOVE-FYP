import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'image_details.dart';

class HomeGridPage extends StatefulWidget {
  const HomeGridPage({super.key});

  @override
  _HomeGridPageState createState() => _HomeGridPageState();
}

class _HomeGridPageState extends State<HomeGridPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(); // Firebase reference
  List<Map<String, String>> homeImagePaths = []; // List to store fetched data
  bool _isLoading = true; // To show loading spinner

  @override
  void initState() {
    super.initState();
    _fetchHomeImages(); // Fetch data from Firebase
  }

  Future<void> _fetchHomeImages() async {
    try {
      DatabaseReference homeRef = _databaseRef.child('RENOVATION/NEW_HOME');
      DataSnapshot snapshot = await homeRef.get();

      if (snapshot.exists) {
        List<Map<String, String>> fetchedImages = [];
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((key, value) {
          fetchedImages.add({
            'path': value['path'], // Assuming Firebase has 'path' field for image URL
            'title': value['title'], // Assuming Firebase has 'title' field for image title
          });
        });

        setState(() {
          homeImagePaths = fetchedImages;
          _isLoading = false; // Data loaded, stop showing the spinner
        });
      }
    } catch (e) {
      print('Error fetching home images: $e');
      setState(() {
        _isLoading = false; // Stop loading spinner if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Design Ideas'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: homeImagePaths.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Navigate to ImageDetailPage when an image is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageDetailPage(
                      imagePath: homeImagePaths[index]['path']!,
                      title: homeImagePaths[index]['title']!,
                      description: "This is a description for ${homeImagePaths[index]['title']}.",
                      relatedImages: homeImagePaths, // Pass the list of images for the related section
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      homeImagePaths[index]['path']!, // Using network images from Firebase
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error), // Error handling
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    homeImagePaths[index]['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
