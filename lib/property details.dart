import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:sample/property.dart';

class PropertyDetailsPage extends StatelessWidget {
  final Property property;

  const PropertyDetailsPage({super.key, required this.property});

  // Function to request phone permission and open the phone dialer
  Future<void> _launchPhoneDialer(String phoneNumber) async {
    // Check phone permission status
    PermissionStatus permission = await Permission.phone.status;

    if (!permission.isGranted) {
      // Request permission if not granted
      permission = await Permission.phone.request();
    }

    // If permission is granted, proceed with launching the phone dialer
    if (permission.isGranted) {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone dialer with $phoneNumber';
      }
    } else {
      // Show a message to the user if permission is denied
      print("Phone permission denied");
    }
  }

  // Function to save the property to SharedPreferences
  Future<void> _saveProperty() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedProperties = prefs.getStringList('savedProperties') ?? [];

    // Check if property is already saved to avoid duplicates
    if (!savedProperties.contains(property.imageUrl)) {
      savedProperties.add(property.imageUrl); // Save the property image URL (can extend to more details)
      await prefs.setStringList('savedProperties', savedProperties);
      print("Property saved!");
    } else {
      print("Property is already saved.");
    }
  }

  // Utility method to extract owner name from the image URL
  String _getOwnerNameFromImageUrl(String imageUrl) {
    final segments = imageUrl.split('/');
    return segments.length > 1 ? segments[1] : 'Unknown Owner'; // Extract folder name (owner's name)
  }

  // Utility method to construct the contact image path based on the owner's folder
  String _getContactImagePath(String ownerName) {
    return 'assets/$ownerName/contact/contact.jpeg'; // Path to contact image based on owner
  }

  @override
  Widget build(BuildContext context) {
    // Extract the owner's name from the image URL
    final ownerName = _getOwnerNameFromImageUrl(property.imageUrl);
    final contactImagePath = _getContactImagePath(ownerName);

    return Scaffold(
      appBar: AppBar(
        title: Text(property.title),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image with fallback error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.asset(
                  property.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/error_image.png', height: 250, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),

              // Property Price and Address
              Text(
                property.price,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFB46146)),
              ),
              const SizedBox(height: 8),
              Text(
                property.address,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Property Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                property.description,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Property Owner Information
              const Text(
                'Property Owner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(contactImagePath), // Owner's contact image
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName, // Display the extracted owner name
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.phone, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            '+1 234 567 890', // Placeholder for agent phone number
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact and Save Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _launchPhoneDialer('+1 234 567 890'); // Launch phone dialer on button press
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text(
                      'Contact Owner',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _saveProperty(); // Save the property on button press
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Property Saved')),
                      );
                    },
                    icon: const Icon(Icons.bookmark, color: Colors.white),
                    label: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
