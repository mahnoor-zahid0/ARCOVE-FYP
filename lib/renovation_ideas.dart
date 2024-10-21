import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RenovationsPage extends StatefulWidget {
  @override
  _RenovationsPageState createState() => _RenovationsPageState();
}

class _RenovationsPageState extends State<RenovationsPage> with AutomaticKeepAliveClientMixin {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<RenovationItem> renovationItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRenovationMedia();
  }

  Future<void> _fetchRenovationMedia() async {
    try {
      final ListResult result = await _storage.ref('RENOVATION/RENOVATION_MAIN').listAll();
      List<RenovationItem> fetchedItems = [];

      for (var item in result.items) {
        String downloadUrl = await item.getDownloadURL();

        if (item.name.endsWith('.mp4')) {
          fetchedItems.add(RenovationItem(type: MediaType.video, mediaUrl: downloadUrl));
        } else {
          fetchedItems.add(RenovationItem(type: MediaType.image, mediaUrl: downloadUrl));
        }
      }

      setState(() {
        renovationItems = fetchedItems;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching media: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovations', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: renovationItems.length,
        itemBuilder: (context, index) {
          final item = renovationItems[index];
          return GestureDetector(
            onTap: () {
              // Navigate to MediaDetailPage when an item is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaDetailPage(media: item),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: item.type == MediaType.image
                  ? ImageGridItem(imageUrl: item.mediaUrl)
                  : VideoGridItem(videoUrl: item.mediaUrl),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ImageGridItem extends StatelessWidget {
  final String imageUrl;

  const ImageGridItem({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }
}

class VideoGridItem extends StatefulWidget {
  final String videoUrl;

  const VideoGridItem({super.key, required this.videoUrl});

  @override
  _VideoGridItemState createState() => _VideoGridItemState();
}

class _VideoGridItemState extends State<VideoGridItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
      }).catchError((error) {
        print("Error initializing video: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            const Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 50,
            ),
        ],
      ),
    )
        : const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// Enum to distinguish between image and video media types
enum MediaType { image, video }

// Class to represent a renovation item (either image or video)
class RenovationItem {
  final MediaType type;
  final String mediaUrl;

  RenovationItem({required this.type, required this.mediaUrl});
}

// Page to show image or video in full size with a Save option
class MediaDetailPage extends StatefulWidget {
  final RenovationItem media;

  const MediaDetailPage({super.key, required this.media});

  @override
  _MediaDetailPageState createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> _saveMedia() async {
    if (isLoggedIn) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedMedia = prefs.getStringList('savedProperties') ?? [];
      savedMedia.add(widget.media.mediaUrl);
      await prefs.setStringList('savedProperties', savedMedia);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.media.type == MediaType.image ? 'Image Detail' : 'Video Detail', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.media.type == MediaType.image
                ? Image.network(
              widget.media.mediaUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
            )
                : VideoGridItem(videoUrl: widget.media.mediaUrl),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isLoggedIn ? _saveMedia : null,
            icon: const Icon(Icons.bookmark, color: Colors.white,),
            label: const Text('Save', style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoggedIn ? Color(0xFFB46146) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
