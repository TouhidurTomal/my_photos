import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'CollectionPhotosPage.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

class UploaderProfilePage extends StatelessWidget {
  final String profileImageUrl;
  final String userName;
  final List<Map<String, dynamic>> collections; // Must contain `id`

  const UploaderProfilePage({
    super.key,
    required this.profileImageUrl,
    required this.userName,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Section with User Info
          Stack(
            children: [
              Container(
                color: Colors.black26,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20.0),
                    CircleAvatar(
                      radius: 50.0,
                      backgroundImage:
                          CachedNetworkImageProvider(profileImageUrl),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 35.0,
                left: 15.0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          // Collections Section
          Expanded(
            child: Container(
              color: Colors.white,
              child: collections == null
                  ? const Center(
                      child: Text(
                        'Failed to load collections',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    )
                  : collections.isEmpty
                      ? const Center(
                          child: Text(
                            'No collections found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 10.0),
                            const Text(
                              'Collections',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(10.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: collections.length,
                                itemBuilder: (context, index) {
                                  final collection = collections[index];
                                  final String? collectionId =
                                      collection['id']?.toString();
                                  final String? coverPhotoUrl =
                                      collection['cover_photo']?['urls']
                                          ?['regular'];
                                  final String name = collection['name'] ??
                                      'Unnamed Collection';
                                  final String description =
                                      collection['description'] ??
                                          'No description';
                                  final int totalPhotos =
                                      collection['total_photos'] ?? 0;

                                  return GestureDetector(
                                    onTap: () {
                                      if (collectionId != null &&
                                          collectionId.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CollectionPhotosPage(
                                              collectionId: collection['id']
                                                      ?.toString() ??
                                                  collectionId,
                                              collectionName:
                                                  collection['name'],
                                              coverPhotoUrl: collection[
                                                      'coverPhotoUrl'] ??
                                                  'https://via.placeholder.com/400',
                                              description:
                                                  collection['description'] ??
                                                      description,
                                              uploaderName: '',
                                              uploaderProfileImage: '',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Stack(
                                      children: [
                                        // Background Image
                                        CachedNetworkImage(
                                          imageUrl: collection[
                                                  'coverPhotoUrl'] ??
                                              'https://via.placeholder.com/400',
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                                child: Icon(Icons.image)),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.error,
                                                  color: Colors.red),
                                            ),
                                          ),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                        // Bottom Overlay with Name and Description
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.transparent
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.0,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  description,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12.0,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Total Photos Badge
                                        Positioned(
                                          top: 8.0,
                                          right: 8.0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6.0),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.transparent
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.photo,
                                                  color: Colors.white,
                                                  size: 16.0,
                                                ),
                                                const SizedBox(width: 4.0),
                                                Text(
                                                  '${collection['totalPhotos']} photos',
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
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
