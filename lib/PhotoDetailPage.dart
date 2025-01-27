import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoDetailPage extends StatelessWidget {
  final String imageUrl;

  const PhotoDetailPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Interactive Viewer for Zoom and Pan
              InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Back Button
              Positioned(
                top: 20,
                left: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              // Download and Share Buttons
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () async {
                        await _saveImage(context, imageUrl);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Icon(Icons.download, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () async {
                        await _shareImage(imageUrl);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage(BuildContext context, String imageUrl) async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      // Use DefaultCacheManager to download the image and retrieve the cached file
      final cachedImage = await DefaultCacheManager().getSingleFile(imageUrl);

      // Save the image to the public downloads directory
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }

      // Extract filename and ensure it includes an image extension
      String fileName = imageUrl.split('/').last.split('?').first; // Extract filename
      if (!fileName.contains('.')) {
        fileName += '.jpg'; // Default to .jpg if no extension is present
      }

      final filePath = '${downloadsDirectory.path}/$fileName';
      final savedImage = await cachedImage.copy(filePath);

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image saved to ${savedImage.path}")),
      );

      // Refresh the gallery to make the image appear
      _refreshGallery(savedImage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save image: $e")),
      );
    }
  }

// Refresh the gallery to make the saved image visible
  void _refreshGallery(File file) {
    try {
      final path = file.path;
      File(path).createSync();
    } catch (e) {
      debugPrint("Failed to refresh gallery: $e");
    }
  }





  Future<void> _shareImage(String imageUrl) async {
    try {
      final cachedImage = await DefaultCacheManager().getSingleFile(imageUrl);
      await Share.share(imageUrl);
    } catch (e) {
      debugPrint("Error sharing image: $e");
    }
  }
}
