import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'package:camera/camera.dart';
import 'dart:math';

class RealisticDesignVisualization extends StatefulWidget {
  const RealisticDesignVisualization({super.key});

  @override
  _RealisticDesignVisualizationState createState() => _RealisticDesignVisualizationState();
}

class _RealisticDesignVisualizationState extends State<RealisticDesignVisualization> {
  int _selectedIndex = 2; // Default index for the visualization page

  List<String> folderNames = []; // To hold the names of subfolders under ARVIEW
  bool isLoading = true; // To show a loading indicator while fetching folders

  @override
  void initState() {
    super.initState();
    _fetchFoldersFromFirebase();
  }

  // Fetch all subfolders under the 'ARVIEW' folder in Firebase Storage
  Future<void> _fetchFoldersFromFirebase() async {
    final storageRef = FirebaseStorage.instance.ref().child('ARVIEW'); // Reference to ARVIEW folder

    try {
      final ListResult result = await storageRef.listAll(); // List all subfolders
      final List<String> fetchedFolders = [];

      for (var prefix in result.prefixes) {
        fetchedFolders.add(prefix.name); // Add the subfolder name
      }

      setState(() {
        folderNames = fetchedFolders;
        isLoading = false; // Stop loading after fetching subfolders
      });
    } catch (e) {
      print('Error fetching folders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handles navigation when a bottom navigation item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Visualization', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading indicator while fetching folders
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: folderNames.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // When a folder is tapped, navigate to the folder's contents
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FolderContentsPage(folderName: folderNames[index]),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB46146),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  folderNames[index], // Display the folder name
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Page to display the contents of a selected folder
class FolderContentsPage extends StatefulWidget {
  final String folderName;

  const FolderContentsPage({super.key, required this.folderName});

  @override
  _FolderContentsPageState createState() => _FolderContentsPageState();
}

class _FolderContentsPageState extends State<FolderContentsPage> {
  List<Design> designs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDesignsFromFolder(widget.folderName);
  }

  // Fetch images from a specific folder in Firebase Storage
  Future<void> _fetchDesignsFromFolder(String folderName) async {
    final List<Design> fetchedDesigns = [];
    final storageRef = FirebaseStorage.instance.ref().child('ARVIEW/$folderName'); // Fetch from ARVIEW/subfolder

    try {
      final ListResult result = await storageRef.listAll(); // List all files in the subfolder

      for (var ref in result.items) {
        final String downloadUrl = await ref.getDownloadURL(); // Get the download URL for each file
        final String title = ref.name.split('.').first; // Use the file name as the title

        fetchedDesigns.add(Design(imageUrl: downloadUrl, title: title)); // Add to the list of designs
      }

      setState(() {
        designs = fetchedDesigns;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching designs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName, style: TextStyle(color: Colors.white),), // Display the folder name in the AppBar
        backgroundColor: const Color(0xFFB46146),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching folder contents
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: designs.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Navigate to the detail page of the selected design
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DesignDetailPage(design: designs[index]),
                  ),
                );
              },
              child: DesignTile(design: designs[index]), // Show each design as a tile
            );
          },
        ),
      ),
    );
  }
}

// Design model class
class Design {
  final String imageUrl;
  final String title;

  Design({required this.imageUrl, required this.title});
}

// Design tile widget to display each design
class DesignTile extends StatelessWidget {
  final Design design;

  const DesignTile({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
            child: Image.network(
              design.imageUrl,
              height: 200, // Increased height for the image
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded( // Use Expanded to avoid overflow
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                design.title,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Detail page to show a full-sized image of a design

class DesignDetailPage extends StatelessWidget {
  final Design design;

  const DesignDetailPage({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(design.title, style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFFB46146),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white,),
            onPressed: () async {
              await _saveDesign(context, design); // Save the design
            },
            tooltip: 'Save',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(
                  design.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                design.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Contact Owner Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.contact_mail,color: Colors.white,),
                label: const Text('Contact Owner', style: TextStyle(color: Colors.white,),),
                onPressed: () {
                  _contactOwner(context);
                },
              ),

              const SizedBox(height: 16),

              // View in AR Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB46146),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.view_in_ar, color: Colors.white,),
                label: const Text('View in AR', style: TextStyle(color: Colors.white,),),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ARViewPage(imageUrl: design.imageUrl), // Pass the selected image URL
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

  // Save the design using SharedPreferences
  Future<void> _saveDesign(BuildContext context, Design design) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the saved designs from SharedPreferences
    List<String> savedDesigns = prefs.getStringList('savedDesigns') ?? [];

    // Create a design map and encode it as a JSON string
    String designJson = json.encode({
      'title': design.title,
      'imageUrl': design.imageUrl,
    });

    // Add the new design to the saved designs
    savedDesigns.add(designJson);

    // Save the updated list
    await prefs.setStringList('savedDesigns', savedDesigns);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Design saved!')),
    );
  }

  // Function to handle "Contact Owner" button click
  void _contactOwner(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Owner'),
          content: const Text('You can contact the owner via email or phone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to handle "View in AR" button click
  void _viewInAR(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('View in AR'),
          content: const Text('Launching AR view...'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class ARViewPage extends StatefulWidget {
  final String imageUrl;

  ARViewPage({required this.imageUrl});

  @override
  _ARViewPageState createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  CameraController? _cameraController;
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _position = Offset(100, 100);
  Offset _previousOffset = Offset.zero;
  double _rotation = 0.0; // For rotation
  double _previousRotation = 0.0; // Store previous rotation

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;
      _cameraController = CameraController(camera, ResolutionPreset.high);
      await _cameraController?.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('View in AR'),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_cameraController!),

          // The selected image as an overlay
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onScaleStart: (details) {
                _previousScale = _scale;
                _previousRotation = _rotation;
                _previousOffset = details.focalPoint - _position;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Handle scaling
                  _scale = _previousScale * details.scale;
                  _scale = _scale.clamp(0.5, 3.0); // Clamp the scale

                  // Handle rotation
                  _rotation = _previousRotation + details.rotation;

                  // Handle dragging
                  _position = details.focalPoint - _previousOffset;
                });
              },
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(0.0, 0.0)
                  ..rotateZ(_rotation) // Rotate based on user gestures
                  ..scale(_scale), // Scale based on pinch gesture
                child: Image.network(
                  widget.imageUrl,
                  width: 150, // Adjust width as needed
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}