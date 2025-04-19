// lib/src/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'editor_screen.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  StreamSubscription? _intentDataStreamSubscription;
  final _flutterSharingIntent = FlutterSharingIntent();

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  Future<void> _initSharingIntent() async {
    // 仅监听应用运行中的分享
    _intentDataStreamSubscription = _flutterSharingIntent.getMediaStream()
        .listen((List<SharedFile> value) {
      _handleSharedFiles(value);
      print('HomeScreen: 收到运行中分享');
    }, onError: (err) {
      debugPrint("HomeScreen: getIntentDataStream error: $err");
    });

    // 不再处理初始分享，因为已经在MyApp中处理
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _handleSharedFiles(List<SharedFile> files) {
    if (files.isNotEmpty && mounted) {
      print('HomeScreen: 处理分享文件: ${files.first.value}');
      setState(() {
        _selectedImage = XFile(files.first.value!);
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(
              selectedImage: _selectedImage,
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      // Enable higher quality images for web
      maxWidth: kIsWeb ? 1920 : null,
      maxHeight: kIsWeb ? 1080 : null,
      imageQuality: kIsWeb ? 95 : 90,
    );
    
    if (!mounted) return;
    
    setState(() {
      _selectedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 32, top: 32),
                    child: Text(
                      "Let's\nGet it\nStarted",
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 48,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.fromLTRB(32, 0, 32, MediaQuery.of(context).padding.bottom + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          FilledButton.icon(
                            onPressed: () async {
                              await _pickImage();
                              if (mounted && _selectedImage != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditorScreen(
                                      selectedImage: _selectedImage,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('From Gallery'),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 56),
                                maximumSize: const Size(300, 56),
                            ),
                          ),

                        const SizedBox(height: 12),
                        
                        FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditorScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.create),
                            label: const Text('From Scratch'),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 56),
                                maximumSize: const Size(300, 56),
                            ),
                          ),
                          const SizedBox(height: 24),
                      ],
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
