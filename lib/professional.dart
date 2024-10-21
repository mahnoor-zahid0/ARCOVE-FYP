import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PROFESSIONAL/search/search_home.dart';
import 'professional_chat.dart';
class ProfessionalPage extends StatefulWidget {
  @override
  _ProfessionalPageState createState() => _ProfessionalPageState();
}

class _ProfessionalPageState extends State<ProfessionalPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Professional> followedProfessionals = [];
  List<Professional> otherProfessionals = [];
  List<String> uploadedImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfessionalsAndUploads();
  }

  // Fetch professionals the user is following and their uploads from Firebase Storage and Firestore
  Future<void> _fetchProfessionalsAndUploads() async {
    try {
      // Fetch the user ID
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Fetch professionals the user is following from Firestore
      var followingSnapshot = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('following')
          .get();

      List<String> followedProfessionalIds = followingSnapshot.docs.map((doc) => doc.id).toList();

      List<Professional> fetchedFollowedProfessionals = [];
      List<Professional> fetchedOtherProfessionals = [];

      // Fetch all professional folders
      final ListResult professionalsList = await _storage.ref().child('Professionals').listAll();

      for (var folderRef in professionalsList.prefixes) {
        String professionalId = folderRef.name;

        // If the professional is followed, fetch their uploads and add to followed list
        if (followedProfessionalIds.contains(professionalId)) {
          String profileImageUrl = await _getProfileImageUrl(professionalId);
          fetchedFollowedProfessionals.add(Professional(
            imageUrl: profileImageUrl,
            name: professionalId,
            phone: 'Unknown', // Placeholder phone number
            agency: 'Unknown', // Placeholder agency
            lastMessage: 'No recent messages', // Placeholder message
          ));

          // Fetch uploads for each followed professional
          ListResult uploadsList = await _storage
              .ref()
              .child('Professionals/$professionalId/uploads')
              .listAll();

          for (var item in uploadsList.items) {
            String downloadUrl = await item.getDownloadURL();
            uploadedImages.add(downloadUrl); // Add the image URL to the list
          }
        } else {
          // Add to unfollowed professionals list
          fetchedOtherProfessionals.add(Professional(
            imageUrl: 'assets/placeholder.png',
            name: professionalId,
            phone: 'Unknown',
            agency: 'Unknown',
            lastMessage: 'No recent messages',
          ));
        }
      }

      setState(() {
        followedProfessionals = fetchedFollowedProfessionals;
        otherProfessionals = fetchedOtherProfessionals;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching professionals or uploads: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch profile image URL for a professional
  Future<String> _getProfileImageUrl(String professionalId) async {
    try {
      final ref = _storage.ref().child('Professionals/$professionalId/profile.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return 'https://via.placeholder.com/150'; // Placeholder image if profile image is not found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professionals'),
        backgroundColor: const Color(0xFFB46146),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB46146),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // Uploads Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Uploads',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: uploadedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(uploadedImages[index]),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white),

          // Professionals with Messages Section (Followed Professionals)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Professional',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: followedProfessionals.length,
            itemBuilder: (context, index) {
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(followedProfessionals[index].imageUrl),
                  ),
                  title: Text(followedProfessionals[index].name,
                      style: const TextStyle(color: Color(0xFFB46146))),
                  subtitle: Text(followedProfessionals[index].lastMessage),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Color(0xFFB46146)),
                  onTap: () {
                    // Navigate to professional's chat page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfessionalChatPage(
                          name: followedProfessionals[index].name,
                          imageUrl: followedProfessionals[index].imageUrl,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(color: Colors.white),

          // Follow More Section (Unfollowed Professionals)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Follow More',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: otherProfessionals.length,
            itemBuilder: (context, index) {
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(otherProfessionals[index].imageUrl),
                  ),
                  title: Text(otherProfessionals[index].name,
                      style: const TextStyle(color: Color(0xFFB46146))),
                  subtitle: Text(otherProfessionals[index].agency),
                  trailing: const Icon(Icons.add_circle, color: Colors.green),
                  onTap: () {
                    // Navigate to the VisitProPage when the + button is clicked
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisitProPage(
                          profileId: otherProfessionals[index].name,
                          name: otherProfessionals[index].name,
                          profilePicUrl: otherProfessionals[index].imageUrl,
                          description: otherProfessionals[index].agency,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Professional {
  final String imageUrl;
  final String name;
  final String phone;
  final String agency;
  final String lastMessage;

  Professional({
    required this.imageUrl,
    required this.name,
    required this.phone,
    required this.agency,
    required this.lastMessage,
  });
}
