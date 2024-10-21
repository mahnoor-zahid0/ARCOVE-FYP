import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class InteriorDesignPage extends StatefulWidget {
  const InteriorDesignPage({Key? key}) : super(key: key);

  @override
  _InteriorDesignPageState createState() => _InteriorDesignPageState();
}

class _InteriorDesignPageState extends State<InteriorDesignPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, String>> mediaFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMediaFiles();
  }

  // Fetch images from Firebase Storage
  Future<void> _fetchMediaFiles() async {
    try {
      List<Map<String, String>> fetchedMediaFiles = [];

      // Fetch images from /RENOVATION/BEDROOMS
      final ListResult imagesResult = await _storage.ref('/RENOVATION/BEDROOMS').listAll();
      for (var item in imagesResult.items) {
        String imageUrl = await item.getDownloadURL();
        fetchedMediaFiles.add({'path': imageUrl, 'title': item.name, 'type': 'image'});
      }

      // Fetch videos from /videos
      final ListResult videosResult = await _storage.ref('/videos').listAll();
      for (var item in videosResult.items) {
        String videoUrl = await item.getDownloadURL();
        fetchedMediaFiles.add({'path': videoUrl, 'title': item.name, 'type': 'video'});
      }

      setState(() {
        mediaFiles = fetchedMediaFiles;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching media files: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interior Designs'),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: mediaFiles.length,
          itemBuilder: (context, index) {
            final mediaItem = mediaFiles[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InteriorImageDetailPage(
                      mediaUrl: mediaItem['path']!,
                      title: mediaItem['title']!,
                      description: 'This is a detailed description of the interior design.',
                      relatedImages: mediaFiles,
                      mediaType: mediaItem['type']!,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: mediaItem['type'] == 'image'
                        ? Image.network(
                      mediaItem['path']!,
                      fit: BoxFit.cover,
                    )
                        : VideoGridItem(videoUrl: mediaItem['path']!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mediaItem['title']!,
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

class InteriorImageDetailPage extends StatelessWidget {
  final String mediaUrl;
  final String title;
  final String description;
  final List<Map<String, String>> relatedImages;
  final String mediaType;

  const InteriorImageDetailPage({
    Key? key,
    required this.mediaUrl,
    required this.title,
    required this.description,
    required this.relatedImages,
    required this.mediaType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interior Design Detail'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            mediaType == 'image'
                ? Image.network(
              mediaUrl,
              fit: BoxFit.cover,
            )
                : VideoDetailWidget(videoUrl: mediaUrl),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Related Images',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                children: List.generate(relatedImages.length, (int index) {
                  return StaggeredGridTile.fit(
                    crossAxisCellCount: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InteriorImageDetailPage(
                              mediaUrl: relatedImages[index]['path']!,
                              title: relatedImages[index]['title']!,
                              description: "This is a related image description.",
                              relatedImages: relatedImages,
                              mediaType: relatedImages[index]['type']!,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          relatedImages[index]['type'] == 'image'
                              ? Image.network(
                            relatedImages[index]['path']!,
                            fit: BoxFit.cover,
                          )
                              : VideoGridItem(videoUrl: relatedImages[index]['path']!),
                          const SizedBox(height: 4),
                          Text(
                            relatedImages[index]['title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for video in GridView
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
        setState(() {}); // Update UI when the video is ready
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
        ? Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        const Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
      ],
    )
        : const Center(child: CircularProgressIndicator());
  }
}

// Full-screen video widget for detail page
class VideoDetailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoDetailWidget({super.key, required this.videoUrl});

  @override
  _VideoDetailWidgetState createState() => _VideoDetailWidgetState();
}

class _VideoDetailWidgetState extends State<VideoDetailWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play(); // Auto play the video
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
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : const Center(child: CircularProgressIndicator());
  }
}
