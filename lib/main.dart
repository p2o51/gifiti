import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/home_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'src/screens/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  XFile? _sharedImage;
  final _flutterSharingIntent = FlutterSharingIntent();

  @override
  void initState() {
    super.initState();
    // 检查初始分享意图
    _checkInitialSharedImage();
  }

  Future<void> _checkInitialSharedImage() async {
    try {
      final List<SharedFile> initialShared = await _flutterSharingIntent.getInitialSharing();
      if (initialShared.isNotEmpty && initialShared.first.value != null) {
        setState(() {
          _sharedImage = XFile(initialShared.first.value!);
        });
        print('MyApp: 检测到初始分享图片: ${_sharedImage?.path}');
      }
    } catch (e) {
      print('MyApp: 获取初始分享图片时出错: $e');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple);
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        );

        // Update system UI overlay style based on theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );

        Widget initialScreen;
        if (_sharedImage != null) {
          // 如果有分享图片，直接打开编辑器屏幕
          initialScreen = EditorScreen(selectedImage: _sharedImage);
          print('MyApp: 启动编辑器屏幕，使用分享图片');
        } else {
          // 否则显示主屏幕
          initialScreen = const HomeScreen();
          print('MyApp: 启动主屏幕');
        }

        return MaterialApp(
          title: 'Gifiti',
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
          ),
          home: initialScreen,
        );
      },
    );
  }
}
