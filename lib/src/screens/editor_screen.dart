import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/editor_selector.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class EditorScreen extends StatefulWidget {
  final XFile? selectedImage;
  
  const EditorScreen({
    super.key,
    this.selectedImage,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  EditorMode _selectedMode = EditorMode.emojis;
  Color _selectedColor = Colors.blue;
  String _selectedEmoji = '';
  double _density = 2.0;
  double _size = 1.0;

  // 添加一个 GlobalKey 用于 RepaintBoundary
  final GlobalKey _boundaryKey = GlobalKey();
  // ScrollController for small screens
  final ScrollController _scrollController = ScrollController();

  // 添加随机 emoji 列表
  final List<String> _defaultEmojis = ['🌸', '🌺', '🌹', '🌷', '🌼', '🌻', '🍀', '🌿', '🌱', '🌳', '🌴', '🌵', '🍄', '🦋', '🐝', '⭐️', '✨', '💫', '🌙', '☁️'];
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 添加随机生成参数的方法
  void _generateRandomParameters() {
    final random = Random();
    
    setState(() {
      // 随机选择1-3个emoji组合
      final emojiCount = random.nextInt(3) + 1;
      final selectedEmojis = List.generate(
        emojiCount,
        (_) => _defaultEmojis[random.nextInt(_defaultEmojis.length)]
      );
      _selectedEmoji = selectedEmojis.join();
      
      // 随机颜色
      _selectedColor = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      );
      
      // 随机密度 (0.0-3.0)
      _density = random.nextDouble() * 3.0;
      
      // 随机大小 (0.0-5.0)
      _size = random.nextDouble() * 5.0;
    });
  }

  void _handleColorChanged(Color color) {
    setState(() {
      _selectedColor = color;
    });
    // TODO: 更新图片显示区域的内容
  }

  void _handleEmojiChanged(String emoji) {
    setState(() {
      _selectedEmoji = emoji;
    });
    // TODO: 更新图片显示区域的内容
  }

  void _handleDensityChanged(double density) {
    setState(() {
      _density = density;
    });
    // TODO: 更新图片显示区域的内容
  }

  void _handleSizeChanged(double size) {
    setState(() {
      _size = size;
    });
    // TODO: 更新图片显示区域的内容
  }

  List<Widget> _generateEmojiGrid(double containerSize) {
    if (_selectedEmoji.isEmpty) return [];

    final emojis = <Widget>[];
    final adjustedDensity = _density + 2;
    final cols = (adjustedDensity * 2).floor();
    final rows = adjustedDensity.floor();
    final emojiArray = _selectedEmoji.characters.toList();
    
    if (emojiArray.isEmpty) return emojis;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final isOddCol = col % 2 == 1;
        
        // 计算位置
        final x = (col * 100.0) / cols;
        final y = (row * 100.0) / rows + (isOddCol ? 50.0 / rows : 0);
        
        // 选择 emoji（循环使用输入的emoji）
        final index = col % emojiArray.length;
        final currentEmoji = emojiArray[index];

        emojis.add(
          Positioned(
            left: x / 100 * containerSize,
            top: y / 100 * containerSize,
            child: Transform.translate(
              offset: const Offset(-0.5, -0.5),
              child: Text(
                currentEmoji,
                style: TextStyle(
                  fontSize: 24 + _size * 8,
                  color: ColorScheme.fromSeed(seedColor: _selectedColor).primary,
                  fontFamily: 'NotoEmoji',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    return emojis;
  }

  Future<String?> _saveImage() async {
    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final double pixelRatio = 6;
      
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_emoji_art_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      if (Platform.isIOS) {
        final result = await ImageGallerySaver.saveFile(tempFile.path);
        await tempFile.delete();
        
        if (result['isSuccess']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ Saved to Photos'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return tempFile.path;
        } else {
          throw Exception('Failed to save to gallery');
        }
      } else {
        final result = await ImageGallerySaver.saveFile(tempFile.path);
        await tempFile.delete();
        
        if (result['isSuccess']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ Saved to Gallery'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return result['filePath'];
        } else {
          throw Exception('Failed to save to gallery');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
      return null;
    }
  }
  
  // Editor canvas widget that's used in both layouts
  Widget _buildEditorCanvas(double containerSize) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Remove the box shadow
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: containerSize,
            height: containerSize,
            color: ColorScheme.fromSeed(seedColor: _selectedColor).secondaryContainer,
            child: Stack(
              children: [
                // Emoji 层放在底部
                ...(_generateEmojiGrid(containerSize)),
                // 图片放在最上层，添加内边距和圆角
                if (widget.selectedImage != null)
                  Positioned.fill(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: containerSize - 128, // 考虑左右边距
                          maxHeight: containerSize - 128, // 考虑上下边距
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(widget.selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Action buttons widget that's used in both layouts
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.add_circle),
          label: const Text('Generate'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 48),
            maximumSize: const Size(200, 48),
          ),
          onPressed: _generateRandomParameters,
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 48),
            maximumSize: const Size(200, 48),
          ),
          onPressed: () async {
            await _saveImage();
          },
        ),
      ],
    );
  }
  
  // Selector widget used in both layouts
  Widget _buildSelector() {
    return EditorSelector(
      selectedMode: _selectedMode,
      onModeChanged: (mode) => setState(() => _selectedMode = mode),
      onColorChanged: _handleColorChanged,
      onEmojiChanged: _handleEmojiChanged,
      onDensityChanged: _handleDensityChanged,
      onSizeChanged: _handleSizeChanged,
      initialColor: _selectedColor,
      initialEmoji: _selectedEmoji,
      initialDensity: _density,
      initialSize: _size,
    );
  }

  // Mobile layout with scrolling content and bottom selector
  Widget _buildMobileLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerSize = screenWidth * 0.95;
    
    return Stack(
      children: [
        // 固定的顶部导航栏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Theme.of(context).colorScheme.background,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    try {
                      // 直接获取图片数据用于分享，使用高分辨率
                      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                      final double pixelRatio = 6; // 使用高分辨率
                      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
                      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                      final bytes = byteData!.buffer.asUint8List();

                      // 创建临时文件用于分享
                      final tempDir = await getTemporaryDirectory();
                      final shareFile = File('${tempDir.path}/share_emoji_art_${DateTime.now().millisecondsSinceEpoch}.png');
                      await shareFile.writeAsBytes(bytes);
                      
                      // 分享文件
                      await Share.shareXFiles([XFile(shareFile.path)]);
                      
                      // 清理临时文件
                      await shareFile.delete();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share image: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Scrollable main content - 添加顶部padding腾出AppBar空间
        Positioned.fill(
          top: 56, // 为顶部导航栏留出空间
          bottom: MediaQuery.of(context).size.height * 0.25, // Reserve space for the selector
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Canvas
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _buildEditorCanvas(containerSize),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildActionButtons(),
                ),
                // Add extra space at the bottom to ensure content doesn't get hidden behind the selector
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
        
        // Bottom selector
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false, // 顶部不需要 SafeArea
            child: _buildSelector(),
          ),
        ),
      ],
    );
  }
  
  // Desktop/tablet layout with side-by-side content
  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerSize = screenWidth * 0.5; // 50% of the screen width
    
    return Column(
      children: [
        // 固定的顶部导航栏
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.background,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton.filledTonal(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  try {
                    // 直接获取图片数据用于分享，使用高分辨率
                    final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                    final double pixelRatio = 6; // 使用高分辨率
                    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
                    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                    final bytes = byteData!.buffer.asUint8List();

                    // 创建临时文件用于分享
                    final tempDir = await getTemporaryDirectory();
                    final shareFile = File('${tempDir.path}/share_emoji_art_${DateTime.now().millisecondsSinceEpoch}.png');
                    await shareFile.writeAsBytes(bytes);
                    
                    // 分享文件
                    await Share.shareXFiles([XFile(shareFile.path)]);
                    
                    // 清理临时文件
                    await shareFile.delete();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to share image: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        
        // 内容区域
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Editor Canvas and action buttons below it
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片容器，添加左边距使其与按钮对齐
                      Padding(
                        padding: EdgeInsets.only(left: 0), // 调整此值以匹配按钮的位置
                        child: _buildEditorCanvas(containerSize),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons 左对齐
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
              
              // Right side - All Controls on a single page
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title removed
                          // All selectors shown at once instead of tabs
                          // Color selector
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Color',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ColorSelector(
                            onColorChanged: _handleColorChanged,
                            initialColor: _selectedColor,
                          ),
                          const SizedBox(height: 16),
                          
                          // Emoji selector
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Emojis',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          EmojiSelector(
                            onEmojiChanged: _handleEmojiChanged,
                            initialEmoji: _selectedEmoji,
                          ),
                          const SizedBox(height: 16),
                          
                          // Layout selector
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Layout',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          LayoutSelector(
                            onDensityChanged: _handleDensityChanged,
                            onSizeChanged: _handleSizeChanged,
                            initialDensity: _density,
                            initialSize: _size,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          // If the pop was successful, no need to do anything
          return;
        }
        // Navigate back manually if needed
        if (mounted && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        // Add an empty bottomNavigationBar to fill the bottom navigation bar area for mobile
        bottomNavigationBar: isLargeScreen
            ? null
            : Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                height: MediaQuery.of(context).padding.bottom,
              ),
        body: SafeArea(
          bottom: isLargeScreen, // Only apply bottom SafeArea on desktop layout
          child: isLargeScreen
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
        ),
      ),
    );
  }
}
