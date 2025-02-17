import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'PhotoDetailPage.dart';
import 'DatabaseHelper.dart';
import 'UploaderProfilePage.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ScrollController controller = ScrollController();
  List<dynamic> photos = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasError = false;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    fetchPhotos();
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        fetchPhotos();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> fetchPhotos() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    final baseUrl = searchQuery != null && searchQuery!.isNotEmpty
        ? 'https://api.unsplash.com/search/photos'
        : 'https://api.unsplash.com/photos';
    final url = Uri.parse(
        '$baseUrl?page=$currentPage&per_page=21&client_id=VYuboabKt79G13scC7Aq6T1Ri3c8pqFPp22YY_CyjLk${searchQuery != null ? '&query=$searchQuery' : ''}');
    final cacheKey = searchQuery != null && searchQuery!.isNotEmpty
        ? 'search_${searchQuery}_page_$currentPage'
        : 'photos_page_$currentPage';

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;

      if (isConnected) {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);

          List<dynamic> fetchedPhotos;
          if (searchQuery != null && searchQuery!.isNotEmpty) {
            fetchedPhotos = responseBody['results'];
          } else {
            fetchedPhotos = responseBody;
          }

          await DefaultCacheManager().putFile(
            cacheKey,
            utf8.encode(json.encode(fetchedPhotos)),
          );

          setState(() {
            if (currentPage == 1) {
              photos = fetchedPhotos;
            } else {
              photos.addAll(fetchedPhotos);
            }
            currentPage++;
          });
        } else {
          throw Exception(
              'Error: ${response.statusCode} - ${response.reasonPhrase}');
        }
      } else {
        final cacheResponse =
            await DefaultCacheManager().getFileFromCache(cacheKey);
        if (cacheResponse != null) {
          final cachedPhotos =
              json.decode(await cacheResponse.file.readAsString());

          setState(() {
            if (currentPage == 1) {
              photos = cachedPhotos;
            } else {
              photos.addAll(cachedPhotos);
            }
          });
        } else if (photos.isEmpty) {
          setState(() {
            hasError = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      print('Error: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<String>>(
          future: DatabaseHelper.instance.getRecentSearches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final recentSearches = snapshot.data ?? [];

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'Search Photos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recentSearches.isNotEmpty)
                            ...recentSearches.map(
                              (search) => GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  setState(() {
                                    photos.clear();
                                    currentPage = 1;
                                    searchQuery = search;
                                  });
                                  await DatabaseHelper.instance
                                      .insertSearch(search);
                                  fetchPhotos();
                                },
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    search,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Center(
                              child: Text(
                                'No recent searches available.',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child:
                      const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    final query = searchController.text.trim();
                    if (query.isNotEmpty) {
                      await DatabaseHelper.instance.insertSearch(query);
                      setState(() {
                        photos.clear();
                        currentPage = 1;
                        searchQuery = query;
                      });
                      fetchPhotos();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Search',
                      style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            searchQuery != null && searchQuery!.isNotEmpty
                ? '$searchQuery Photos'
                : 'My Photos',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black38,
          leading: searchQuery != null && searchQuery!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      searchQuery = null;
                      photos.clear();
                      currentPage = 1;
                      fetchPhotos();
                    });
                  },
                )
              : null,
        ),
        backgroundColor: Colors.black38,
        body: isLoading && photos.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : hasError
                ? const Center(
                    child: Text(
                      'Error loading photos.',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : Stack(
                    children: [
                      GridView.builder(
                        controller: controller,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                          childAspectRatio: 0.70,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return InkWell(
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
                            child: buildImage(photos[index], index),
                          );
                        },
                      ),
                      if (isLoading)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const CupertinoActivityIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showSearchDialog,
          backgroundColor: Colors.white70,
          foregroundColor: Colors.black87,
          child: const Icon(Icons.search),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchUserCollections(
      String username) async {
    final url = Uri.parse(
        'https://api.unsplash.com/users/$username/collections?client_id=VYuboabKt79G13scC7Aq6T1Ri3c8pqFPp22YY_CyjLk');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Print the collections data to debug
        print('Collections data: $data');

        return data.map((collection) {
          return {
            'name': collection['title'],
            'description':
                collection['description'] ?? 'No description available.',
            'totalPhotos': collection['total_photos'],
            'id': collection['id'],
            'coverPhotoUrl': collection['cover_photo']['urls']['small'],
          };
        }).toList();
      } else {
        throw Exception(
            'Failed to fetch collections: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching user collections: $e');
      return [];
    }
  }

  Widget buildImage(Map<String, dynamic> photo, int index) {
    final String imageUrl = photo['urls']['small'];
    final String uploaderProfileImage = photo['user']['profile_image']['small'];
    final String username = photo['user']['username'];
    final String userName = photo['user']['name'];
    final int likes = photo['likes'];

    return Stack(
      children: [
        // Photo
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
          height: double.infinity,
        ),
        // Overlay for uploader and likes
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            height: 30,
            child: Row(
              children: [
                // Uploader profile
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                            child: CircularProgressIndicator(
                          color: Colors.white,
                        )),
                      );

                      // Fetch collections
                      final collections = await fetchUserCollections(username);

                      // Close the loading dialog
                      Navigator.pop(context);

                      // Navigate to UploaderProfilePage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploaderProfilePage(
                            profileImageUrl: photo['user']['profile_image']
                                ['large'],
                            userName: userName,
                            collections: collections,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20.0,
                            backgroundImage: CachedNetworkImageProvider(
                              uploaderProfileImage,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1.0,
                  color: Colors.white24,
                ),
                // Likes
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Handle likes click
                      print('Likes clicked!');
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
