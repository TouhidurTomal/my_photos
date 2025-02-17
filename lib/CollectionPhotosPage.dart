import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'PhotoDetailPage.dart';

class CollectionPhotosPage extends StatefulWidget {
  final String collectionId;
  final String coverPhotoUrl;
  final String collectionName;
  final String description;
  final String uploaderName;
  final String uploaderProfileImage;

  const CollectionPhotosPage({
    super.key,
    required this.collectionId,
    required this.coverPhotoUrl,
    required this.collectionName,
    required this.description,
    required this.uploaderName,
    required this.uploaderProfileImage,
  });

  @override
  State<CollectionPhotosPage> createState() => _CollectionPhotosPageState();
}

class _CollectionPhotosPageState extends State<CollectionPhotosPage> {
  List<Map<String, dynamic>> photos = [];
  int page = 1;
  bool isLoading = false;
  bool hasMore = true;
  final String clientId = 'VYuboabKt79G13scC7Aq6T1Ri3c8pqFPp22YY_CyjLk';
  late ScrollController _scrollController;
  bool isCollapsed = false;
  bool isExpanded = false;

  // Fetch photos with pagination
  Future<void> fetchPhotos() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      final String url =
          'https://api.unsplash.com/collections/${widget.collectionId}/photos?client_id=$clientId&page=$page&per_page=20';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedPhotos = jsonDecode(response.body);

        setState(() {
          if (fetchedPhotos.isNotEmpty) {
            photos.addAll(fetchedPhotos.cast<Map<String, dynamic>>());
            page++;
          } else {
            hasMore = false; // No more photos
          }
        });
      } else {
        print(
            'Error: Failed to fetch photos. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    fetchPhotos();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        fetchPhotos(); // Fetch more photos when nearing the bottom
      }
      setState(() {
        isCollapsed = _scrollController.offset >
            (MediaQuery.of(context).padding.top + kToolbarHeight - 20);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: isCollapsed
                  ? Text(widget.collectionName)
                  : null,
              background: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.coverPhotoUrl,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.red),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.collectionName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: RichText(
                                text: TextSpan(
                                  text: isExpanded
                                      ? widget.description
                                      : widget.description.length > 50
                                      ? '${widget.description.substring(0, 50)}...'
                                      : widget.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                  ),
                                  children: [
                                    if (widget.description.length > 50)
                                      TextSpan(
                                        text: isExpanded
                                            ? " See Less"
                                            : " See More",
                                        style: const TextStyle(
                                          color: Colors.lightBlueAccent,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                if (index == photos.length) {
                  return hasMore
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: Colors.black87,
                      ),
                    ),
                  )
                      : const Center(child: Text('No more photos'));
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      final imageUrl = photos[index]['urls']['regular'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PhotoDetailPage(imageUrl: imageUrl),
                        ),
                      );
                    },
                    child: buildImage(photos[index]),
                  ),
                );
              },
              childCount: photos.length + (hasMore ? 1 : 0),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 0.0,
              mainAxisSpacing: 0.0,
              childAspectRatio: 1.02,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImage(Map<String, dynamic> photo) {
    final String imageUrl = photo['urls']['small'];
    final int likes = photo['likes'];

    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.image)),
          ),
          errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.red),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 250,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            height: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border,
                    color: Colors.white, size: 16.0),
                const SizedBox(width: 4.0),
                Text(
                  likes.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
