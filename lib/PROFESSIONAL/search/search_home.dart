import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat_details.dart'; // Import ChatDetailPage

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _filteredProfiles = [];

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  // Fetch profiles from Firestore
  Future<void> _fetchProfiles() async {
    final snapshot = await FirebaseFirestore.instance.collection('professionals').get();
    List<Map<String, dynamic>> profiles = snapshot.docs.map((doc) {
      return {
        'id': doc.id, // Professional ID for navigation
        'name': doc['name'],
        'profilePicUrl': doc['profilePicture'],
        'description': doc['bio'], // Assuming 'bio' contains the description
      };
    }).toList();

    setState(() {
      _profiles = profiles;
      _filteredProfiles = profiles;
    });
  }

  // Filter profiles based on search text
  void _filterProfiles(String searchText) {
    setState(() {
      _filteredProfiles = _profiles
          .where((profile) =>
          profile['name'].toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFB46146),
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _filterProfiles(value); // Filter profiles based on input
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _filteredProfiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _filteredProfiles.length,
        itemBuilder: (context, index) {
          final profile = _filteredProfiles[index];
          return GestureDetector(
            onTap: () {
              // Navigate to VisitProPage when tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VisitProPage(
                    profileId: profile['id'],
                    name: profile['name'],
                    profilePicUrl: profile['profilePicUrl'],
                    description: profile['description'],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFB46146),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  profile['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VisitProPage extends StatefulWidget {
  final String profileId;
  final String name;
  final String profilePicUrl;
  final String description;

  const VisitProPage({
    Key? key,
    required this.profileId,
    required this.name,
    required this.profilePicUrl,
    required this.description,
  }) : super(key: key);

  @override
  _VisitProPageState createState() => _VisitProPageState();
}

class _VisitProPageState extends State<VisitProPage> {
  List<String> uploadedPosts = [];
  int followersCount = 0;
  int followingCount = 0;
  bool isFollowing = false;
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUploadedPosts();
    _fetchFollowData();
    _checkIfFollowing();
  }

  Future<void> _fetchUploadedPosts() async {
    try {
      final ListResult result = await FirebaseStorage.instance
          .ref('Professionals/${widget.profileId}/Uploads/Posts')
          .listAll();

      List<String> postUrls = [];
      for (var fileRef in result.items) {
        String downloadUrl = await fileRef.getDownloadURL();
        postUrls.add(downloadUrl);
      }

      setState(() {
        uploadedPosts = postUrls;
      });
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  Future<void> _fetchFollowData() async {
    try {
      var followersSnapshot = await FirebaseFirestore.instance
          .collection('Professionals')
          .doc(widget.profileId)
          .collection('followers')
          .get();

      var followingSnapshot = await FirebaseFirestore.instance
          .collection('Professionals')
          .doc(widget.profileId)
          .collection('following')
          .get();

      setState(() {
        followersCount = followersSnapshot.docs.length;
        followingCount = followingSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching follow data: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    var doc = await FirebaseFirestore.instance
        .collection('Professionals')
        .doc(widget.profileId)
        .collection('followers')
        .doc(currentUser!.uid)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  Future<void> _toggleFollow() async {
    setState(() {
      if (isFollowing) {
        followersCount--;
        isFollowing = false;
      } else {
        followersCount++;
        isFollowing = true;
      }
    });

    try {
      if (isFollowing) {
        // Add user to followers
        await FirebaseFirestore.instance
            .collection('Professionals')
            .doc(widget.profileId)
            .collection('followers')
            .doc(currentUser!.uid)
            .set({'userId': currentUser!.uid});

        // Add professional to user's following list
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .collection('following')
            .doc(widget.profileId)
            .set({'professionalId': widget.profileId});
      } else {
        // Remove user from followers
        await FirebaseFirestore.instance
            .collection('Professionals')
            .doc(widget.profileId)
            .collection('followers')
            .doc(currentUser!.uid)
            .delete();

        // Remove professional from user's following list
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .collection('following')
            .doc(widget.profileId)
            .delete();
      }
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  // New method to navigate to ChatDetailPage
  void _navigateToChatPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          otherUserId: widget.profileId,          // Use this parameter name
          otherUserName: widget.name,             // Use this parameter name
          otherUserAvatarUrl: widget.profilePicUrl.isNotEmpty
              ? widget.profilePicUrl
              : 'assets/default_profile.png',   // Use this parameter name
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB46146),
        title: Text(widget.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: widget.profilePicUrl.isNotEmpty
                        ? NetworkImage(widget.profilePicUrl)
                        : const AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB46146),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // Stats: Posts, Followers, Following
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', uploadedPosts.length),
                  GestureDetector(
                    onTap: () => _navigateToFollowList('followers'),
                    child: _buildStatColumn('Followers', followersCount),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToFollowList('following'),
                    child: _buildStatColumn('Following', followingCount),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Follow/Unfollow and Message Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.red : const Color(0xFFB46146),
                    ),
                    onPressed: _toggleFollow,
                    child: Text(isFollowing ? 'UNFOLLOW' : 'FOLLOW'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB46146),
                    ),
                    onPressed: _navigateToChatPage,  // Navigate to chat page
                    child: const Text('MESSAGE'),
                  ),
                ],
              ),
            ),

            // Uploaded Posts Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Posts by ${widget.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            uploadedPosts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uploadedPosts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemBuilder: (context, index) {
                return Image.network(
                  uploadedPosts[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _navigateToFollowList(String type) {
    Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => FollowListPage(
          profileId: widget.profileId,
          type: type,
        ),
        ),
    );
  }
}

class FollowListPage extends StatelessWidget {
  final String profileId;
  final String type; // "followers" or "following"

  const FollowListPage({Key? key, required this.profileId, required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'followers' ? 'Followers' : 'Following'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Professionals')
            .doc(profileId)
            .collection(type)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];

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
